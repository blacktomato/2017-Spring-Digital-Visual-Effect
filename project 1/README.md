# Project 1: High Dynamic Range Imaging

## Introduction
High Dynamic Range (HDR) images have large dynamic ranges which correspond to irradiance value of a scene in physical world. This project implemented a program to assemble an HDR image from a list of images with identical scene but with different exposure times.

#### Image Alignment
- MTB: Ward’s Median Threshold Bitmap

#### High Dynamic Range Image
- Paul Debevec's method
- Robertson's method:

#### Tone Mapping
- Reinhard’s global and local algorithm

## Usage
1. Skip this step if you already have files listing above; otherwise, clone from [here](https://github.com/awinder0230/2017-Spring-Digital-Visual-Effect)
2. Put images with different exposure times under directory input_image/
3. Under directory input_image/, create a .txt file named image_list in the following format:

- line 1: an integer indicating number of images
- line 2: image_filename space shutter_speed_of_the_image
- …
- line N: ...

4. Open main.m under directory src/ with Matlab, there are several settings to adjust according to your preference. To run default settings, simply run the code without changing anything.
  Default Settings:
    - Image Alignment: Not applying.
    - HDR Model: Debevec’s method, more details down below.
    - Tone Mapping: Reinhard’s method, more details down below.  
5. The output HDR image in .hdr format, and the LDR image after tone mapping in .bmp format, are both under directory result/.

## More
More information in Resource/report.pdf
