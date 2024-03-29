# IOSurface stays in use after GPU switch

This project demonstrates that some IOSurfaces stay in use on macOS 10.15 after a GPU switch even when they are no longer attached to a CALayer or shown on the screen.

This app creates a new IOSurface once a second, and sets it on a CALayer.
Additionaly, once per second, all surfaces are queried through -[IOSurface isInUse].
See the end of this file for example output.

## Running the app

Clone the project, and compile and run it as follows:

```
git clone https://github.com/mstange/iosurface-calayer-isinuse
cd iosurface-calayer-isinuse
clang main.m -framework Cocoa -framework QuartzCore -framework IOSurface -o test && ./test
```

## Example output

During this run, I started on the integrated GPU, switched to the discrete GPU
after surface 2 was created, and switched back to the integrated GPU after
surface 6 was created.

You can see that surface 2 stays in use while the discrete GPU is active, even
though surface 2 is no longer attached to a CALayer.
After switching back to the integrated GPU, surface 2 becomes unused.
However, from that point on, surface 6 stays in use.

This was tested on 10.15.2 Beta (19C46a), on a MacBook Pro (15-inch, Late 2016),
with an Intel HD Graphics 530 and an AMD Radeon Pro 460.
GPU switching was performed with the help of the gfxCardStatus app from gfx.io.

```
% clang main.m -framework Cocoa -framework QuartzCore -framework IOSurface -o test && ./test
2019-11-29 17:11:27.702 test[27952:2001784] Creating surface 0
2019-11-29 17:11:28.206 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:28.206 test[27952:2001784]   - IOSurface 0 is in use
2019-11-29 17:11:28.707 test[27952:2001784] Creating surface 1
2019-11-29 17:11:29.210 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:29.210 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:29.210 test[27952:2001784]   - IOSurface 1 is in use
2019-11-29 17:11:29.710 test[27952:2001784] Creating surface 2
2019-11-29 17:11:30.212 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:30.212 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:30.713 test[27952:2001784] Creating surface 3
2019-11-29 17:11:31.215 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:31.215 test[27952:2001784]   - IOSurface 3 is in use
2019-11-29 17:11:31.716 test[27952:2001784] Creating surface 4
2019-11-29 17:11:32.218 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:32.218 test[27952:2001784]   - IOSurface 4 is in use
2019-11-29 17:11:32.719 test[27952:2001784] Creating surface 5
2019-11-29 17:11:33.221 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:33.221 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:33.222 test[27952:2001784]   - IOSurface 5 is in use
2019-11-29 17:11:33.723 test[27952:2001784] Creating surface 6
2019-11-29 17:11:34.224 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 2 is in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:34.224 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:34.724 test[27952:2001784] Creating surface 7
2019-11-29 17:11:35.227 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:35.227 test[27952:2001784]   - IOSurface 7 is in use
2019-11-29 17:11:35.728 test[27952:2001784] Creating surface 8
2019-11-29 17:11:36.230 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:36.230 test[27952:2001784]   - IOSurface 8 is in use
2019-11-29 17:11:36.730 test[27952:2001784] Creating surface 9
2019-11-29 17:11:37.232 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 8 is not in use
2019-11-29 17:11:37.232 test[27952:2001784]   - IOSurface 9 is in use
2019-11-29 17:11:37.732 test[27952:2001784] Creating surface 10
2019-11-29 17:11:38.234 test[27952:2001784] IOSurfaceIsInUse:
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 0 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 1 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 2 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 3 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 4 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 5 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 6 is in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 7 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 8 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 9 is not in use
2019-11-29 17:11:38.234 test[27952:2001784]   - IOSurface 10 is in use
```