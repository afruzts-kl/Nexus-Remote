using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

namespace NexusRemote.Agent.Streaming;

public class ScreenCaptureService : IDisposable
{
    private static readonly ImageCodecInfo? JpegCodec = GetEncoder(ImageFormat.Jpeg);
    private readonly EncoderParameters _encoderParams;
    private readonly EncoderParameter _qualityParam;
    private long _quality = 50;

    private int _targetWidth;
    private int _targetHeight;
    private double _scale = 0.75;
    private uint _frameIndex = 0;

    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll")]
    private static extern IntPtr GetDC(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateCompatibleDC(IntPtr hDC);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth, int nHeight);

    [DllImport("gdi32.dll")]
    private static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);

    [DllImport("gdi32.dll")]
    private static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int dwRop);

    [DllImport("gdi32.dll")]
    private static extern bool DeleteDC(IntPtr hDC);

    [DllImport("gdi32.dll")]
    private static extern bool DeleteObject(IntPtr hObject);

    private const int SRCCOPY = 0x00CC0020;
    private const int SM_CXSCREEN = 0;
    private const int SM_CYSCREEN = 1;

    public ScreenCaptureService()
    {
        _encoderParams = new EncoderParameters(1);
        _qualityParam = new EncoderParameter(Encoder.Quality, _quality);
        _encoderParams.Param[0] = _qualityParam;
        UpdateDimensions();
    }

    public void SetConfig(double scale, long quality)
    {
        _scale = Math.Clamp(scale, 0.25, 1.0);
        _quality = Math.Clamp(quality, 10, 95);
        _qualityParam.Dispose();
        _encoderParams.Param[0] = new EncoderParameter(Encoder.Quality, _quality);
        UpdateDimensions();
    }

    private void UpdateDimensions()
    {
        int screenW = GetSystemMetrics(SM_CXSCREEN);
        int screenH = GetSystemMetrics(SM_CYSCREEN);
        if (screenW <= 0) screenW = 1920;
        if (screenH <= 0) screenH = 1080;

        _targetWidth = (int)(screenW * _scale);
        _targetHeight = (int)(screenH * _scale);

        if (_targetWidth % 2 != 0) _targetWidth--;
        if (_targetHeight % 2 != 0) _targetHeight--;
    }

    public byte[]? CaptureFrame(out int outWidth, out int outHeight)
    {
        outWidth = _targetWidth;
        outHeight = _targetHeight;

        int screenW = GetSystemMetrics(SM_CXSCREEN);
        int screenH = GetSystemMetrics(SM_CYSCREEN);
        if (screenW <= 0) screenW = 1920;
        if (screenH <= 0) screenH = 1080;

        Bitmap? capturedBmp = null;

        // Try GDI BitBlt capture first
        IntPtr hDeskDC = GetDC(IntPtr.Zero);
        if (hDeskDC != IntPtr.Zero)
        {
            IntPtr hMemDC = CreateCompatibleDC(hDeskDC);
            IntPtr hBmp = CreateCompatibleBitmap(hDeskDC, screenW, screenH);
            if (hMemDC != IntPtr.Zero && hBmp != IntPtr.Zero)
            {
                IntPtr hOld = SelectObject(hMemDC, hBmp);
                bool success = BitBlt(hMemDC, 0, 0, screenW, screenH, hDeskDC, 0, 0, SRCCOPY);
                SelectObject(hMemDC, hOld);

                if (success)
                {
                    capturedBmp = Image.FromHbitmap(hBmp);
                }
            }

            if (hBmp != IntPtr.Zero) DeleteObject(hBmp);
            if (hMemDC != IntPtr.Zero) DeleteDC(hMemDC);
            ReleaseDC(IntPtr.Zero, hDeskDC);
        }

        // Fallback: If desktop is locked or non-interactive session
        if (capturedBmp == null)
        {
            capturedBmp = new Bitmap(screenW, screenH);
            using var g = Graphics.FromImage(capturedBmp);
            g.Clear(Color.FromArgb(20, 20, 30));
            using var font = new Font(FontFamily.GenericSansSerif, 24, FontStyle.Bold);
            using var brush = new SolidBrush(Color.White);
            g.DrawString("Desktop Locked / Non-Interactive", font, brush, new PointF(screenW / 4f, screenH / 2f));
        }

        Bitmap outputBmp = capturedBmp;
        bool resized = false;
        if (_targetWidth != screenW || _targetHeight != screenH)
        {
            outputBmp = new Bitmap(_targetWidth, _targetHeight, PixelFormat.Format32bppRgb);
            using (var gResize = Graphics.FromImage(outputBmp))
            {
                gResize.InterpolationMode = InterpolationMode.Bilinear;
                gResize.CompositingQuality = CompositingQuality.HighSpeed;
                gResize.SmoothingMode = SmoothingMode.HighSpeed;
                gResize.DrawImage(capturedBmp, 0, 0, _targetWidth, _targetHeight);
            }
            resized = true;
        }

        try
        {
            using var ms = new MemoryStream();
            using var writer = new BinaryWriter(ms);

            // Magic NXRS (0x4E585253)
            writer.Write((byte)0x4E);
            writer.Write((byte)0x58);
            writer.Write((byte)0x52);
            writer.Write((byte)0x53);

            _frameIndex++;
            writer.Write(SwapBytes(_frameIndex));

            long nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            writer.Write(SwapBytes((ulong)nowMs));

            writer.Write(SwapBytes((ushort)_targetWidth));
            writer.Write(SwapBytes((ushort)_targetHeight));

            // Format (1 = JPEG)
            writer.Write((byte)1);

            if (JpegCodec != null)
            {
                outputBmp.Save(ms, JpegCodec, _encoderParams);
            }
            else
            {
                outputBmp.Save(ms, ImageFormat.Jpeg);
            }

            return ms.ToArray();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ScreenCapture] Compression error: {ex.Message}");
            return null;
        }
        finally
        {
            if (resized) outputBmp.Dispose();
            capturedBmp.Dispose();
        }
    }

    private static ImageCodecInfo? GetEncoder(ImageFormat format)
    {
        return ImageCodecInfo.GetImageEncoders().FirstOrDefault(codec => codec.FormatID == format.Guid);
    }

    private static ushort SwapBytes(ushort x) => (ushort)((x << 8) | (x >> 8));
    private static uint SwapBytes(uint x) => (x << 24) | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | (x >> 24);
    private static ulong SwapBytes(ulong x)
    {
        return ((x & 0x00000000000000FF) << 56) |
               ((x & 0x000000000000FF00) << 40) |
               ((x & 0x0000000000FF0000) << 24) |
               ((x & 0x00000000FF000000) << 8) |
               ((x & 0x000000FF00000000) >> 8) |
               ((x & 0x0000FF0000000000) >> 24) |
               ((x & 0x00FF000000000000) >> 40) |
               ((x & 0xFF00000000000000) >> 56);
    }

    public void Dispose()
    {
        _qualityParam.Dispose();
        _encoderParams.Dispose();
    }
}
