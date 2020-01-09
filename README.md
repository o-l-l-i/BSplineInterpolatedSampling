# BSplineInterpolatedSampling

My Unity port of the B-Spline filtering which was presented in the paper [Efficient GPU-Based Texture
Interpolation using Uniform B-Spline](http://mate.tue.nl/mate/pdfs/10318.pdf) by Ruijters et al.

This can be very useful in cases where you need lower resolution texture, but want to have improved image quality with less pixelation.

Note that this implementation presented in the paper requires the texture to use bilinear filtering, as it kind of exploits the bilinear filtered result for the cubic B-spline filtering (at least that's how I understood it).

Below you can see how this filtering effects the well known test image, when zoomed close to the eyes.

### B-Spline interpolation off

![![B-Spline interpolation off image](BSplineInterpolatedSampling_off.png) image](BSplineInterpolatedSampling_off.png)

### B-Spline interpolation on

![![B-Spline interpolation on image](BSplineInterpolatedSampling_on.png) image](BSplineInterpolatedSampling_on.png)
