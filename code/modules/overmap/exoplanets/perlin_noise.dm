/*
Signal Lite is intended to be a more lightweight, easier to use version of my Signal library. Signal Lite
provides the ability to generate the two most "useful" types of noise: Ken Perlin's simplex noise, and
fractal brownian motion (also known as a plasma fractal or fractally combined simplex noise).

Signal Lite, like Signal, can offload computation of noise to a DLL. To use the DLL, copy SignalLite.dll to
your project's root directory.

To begin generating noise, create a noise object as follows:
	var/Noise/noise = new

Note that if you do not want to use the DLL, you need to supply FALSE as the first argument in new. Example:
	var/Noise/noise = new(FALSE)

Or if you have the .DLL in a different location, you can specify that in the second argument in new. Example:
	var/Noise/noise = new(TRUE, "path/to/SignalLite.dll")

After your object has been created, you can get noise with these four procs:
	noise2(x, y) - calculate Perlin's simplex noise in 2D
	noise3(x, y, z) - calculate Perlin's simplex noise in 3D
	fbm2(x, y) - fractal brownian motion in 2D
	fbm3(x, y, z) - fractal brownian motion in 3D

	Example:
		var/Noise/noise = new
		world << noise.noise2(0.5, 0.5) // returns -0.307157

These noise procs return a value from -1 to 1. You will need to use a function to scale this to a range that
is more useful to you. All Noise objects also have a scale(n, low, high) proc. This proc can take your noise value from -1
to 1 and scale it to a specified range. Example:
	var
		Noise/noise = new
		n = noise.noise2(0.5, 0.5) // -0.307157
		world << noise.scale(n, 0, 255) // returns 88.3375

The Noise object also has the following procs:
	enableDLL() - make the Noise object use the DLL
	disableDLL() - stop the Noise object from using the DLL

	setSeed(seed) - set the seed
	randSeed() - set a random seed from -65535 to 65535
	setOctaves(octaves) - set the number of octaves for fractal noise
	setGain(gain) - set the gain for fractal noise
	setOffset(offset) - set the offset for fractal noise
	setFrequency(frequency) - set the frequency for fractal noise
	setLacunarity(lacunarity) - set the lacunarity for fractal noise

	getSeed() - get the seed
	getOctaves() - get the number of octaves
	getGain() - get the gain
	getOffset() - get the offset
	getFrequency() - get the frequency
	getLacunarity() - get the lacunarity

You don't have to concern yourself with the properties like octaves, gain, offset, frequency, and lacunarity
if you don't understand them. The default values will provide good results.

You can create as many Noise objects as you want. This is useful if you need more than one generator seeded
with different values. The seed of an object will change the noise you get from the noise procs. So, two
/Noise objects with two different seeds will produce different values for the same inputs to noise2, noise3,
fbm2, and fbm3.
*/


Noise
	var
		use_dll = TRUE
		dll = "SignalLite.dll"

		seed = 0
		octaves = 7
		gain = 0.5
		offset = 0
		frequency = 1
		lacunarity = 1.89783

	New(_use_dll = TRUE, _dll = "SignalLite.dll")
		use_dll = _use_dll
		if(use_dll)
			dll = _dll
			ASSERT(fexists(dll))
			ASSERT(call(dll, "check")() == "1")

	proc
		enableDLL()
			use_dll = TRUE
			ASSERT(fexists(dll))
			ASSERT(call(dll, "check")() == "1")

		disableDLL()
			use_dll = FALSE

		setSeed(_seed)
			seed = _seed
			if(seed < -65535) seed = 65535
			if(seed > 65535) seed = 65535

		randSeed() seed = rand(-65535, 65535)
		setOctaves(_octaves) octaves = _octaves
		setGain(_gain) gain = _gain
		setOffset(_offset) offset = _offset
		setFrequency(_frequency) frequency = _frequency
		setLacunarity(_lacunarity) lacunarity = _lacunarity
		getSeed() return seed
		getOctaves() return octaves
		getGain() return gain
		getOffset() return offset
		getFrequency() return frequency
		getLacunarity() return lacunarity
		scale(c, x, y) return (y - x) * (c + 1) / 2 + x
		fbm2(x, y)
			if(use_dll) return text2num(call(dll, "fbm2")(num2text(x, 16), num2text(y, 16), num2text(seed, 16), num2text(octaves, 16), num2text(gain, 16), num2text(offset, 16), num2text(frequency, 16), num2text(lacunarity, 16)))

			var
				total = 0.0
				ampl = 1
				i

			x *= frequency
			y *= frequency

			for(i = 0, i < octaves, i ++)
				total += (noise2(x * frequency, y * frequency, seed) + offset) * ampl
				ampl *= gain

				x *= lacunarity
				y *= lacunarity

			return total

		fbm3(x, y, z)
			if(use_dll) return text2num(call(dll, "fbm3")(num2text(x, 16), num2text(y, 16), num2text(z, 16), num2text(seed, 16), num2text(octaves, 16), num2text(gain, 16), num2text(offset, 16), num2text(frequency, 16), num2text(lacunarity, 16)))

			var
				total = 0.0
				ampl = 1
				i

			x *= frequency
			y *= frequency
			z *= frequency

			for(i = 0, i < octaves, i ++)
				total += (noise3(x * frequency, y * frequency, z * frequency, seed) + offset) * ampl
				ampl *= gain

				x *= lacunarity
				y *= lacunarity
				z *= lacunarity

			return total

		noise2(x, y)
			if(use_dll) return text2num(call(dll, "simplex2")(num2text(x, 16), num2text(y, 16), num2text(seed, 16)))

			x += seed
			y += seed

			var
				n0
				n1
				n2

				s = (x + y) * 0.36602540378
				i = round(x + s)
				j = round(y + s)

				t = (i + j) * 0.2113248654
				x0 = x - (i - t)
				y0 = y - (j - t)

				i1
				j1

			if(x0 > y0) { i1 = 1; j1 = 0; }
			else { i1 = 0; j1 = 1; }

			var
				x1 = x0 - i1 + 0.2113248654
				y1 = y0 - j1 + 0.2113248654
				x2 = x0 - 1.0 + 2.0 * 0.2113248654
				y2 = y0 - 1.0 + 2.0 * 0.2113248654

				ii = i & 255
				jj = j & 255

				g1 = __perm_mod12_lut[__perm_lut[ii + __perm_lut[jj + 1] + 1] + 1] * 2
				g2 = __perm_mod12_lut[__perm_lut[ii + i1 + __perm_lut[jj + j1 + 1] + 1] + 1] * 2
				g3 = __perm_mod12_lut[__perm_lut[ii + 1 + __perm_lut[jj + 2] + 1] + 1] * 2

				t0 = 0.5 - x0 * x0 - y0 * y0
				t1 = 0.5 - x1 * x1 - y1 * y1
				t2 = 0.5 - x2 * x2 - y2 * y2

			if (t0 < 0) n0 = 0.0
			else
				t0 *= t0
				n0 = t0 * t0 * (__grad2_lut[g1 + 1] * x0 + __grad2_lut[g1 + 2] * y0)

			if (t1 < 0) n1 = 0.0
			else
				t1 *= t1
				n1 = t1 * t1 * (__grad2_lut[g2 + 1] * x1 + __grad2_lut[g2 + 2] * y1)

			if(t2 < 0) n2 = 0.0
			else
				t2 *= t2
				n2 = t2 * t2 * (__grad2_lut[g3 + 1] * x2 + __grad2_lut[g3 + 2] * y2)

			return 70.0 * (n0 + n1 + n2)

		noise3(x, y, z)
			if(use_dll) return text2num(call(dll, "simplex3")(num2text(x, 16), num2text(y, 16), num2text(z, 16), num2text(seed, 16)))

			x += seed
			y += seed
			z += seed

			var
				n0
				n1
				n2
				n3

				s = (x + y + z) * 0.33333333333
				i = round(x + s)
				j = round(y + s)
				k = round(z + s)

				t = (i + j + k) * 0.16666666666
				x0 = x - (i - t)
				y0 = y - (j - t)
				z0 = z - (k - t)

				i1
				j1
				k1
				i2
				j2
				k2

			if(x0 >= y0)
				if (y0 >= z0) { i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0; }
				else if (x0 >= z0) { i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1; }
				else { i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1; }

			else
				if (y0 < z0) { i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1; }
				else if (x0 < z0) { i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1; }
				else { i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0; }

			var
				x1 = x0 - i1 + 0.16666666666
				y1 = y0 - j1 + 0.16666666666
				z1 = z0 - k1 + 0.16666666666
				x2 = x0 - i2 + 2.0 * 0.16666666666
				y2 = y0 - j2 + 2.0 * 0.16666666666
				z2 = z0 - k2 + 2.0 * 0.16666666666
				x3 = x0 - 1.0 + 3.0 * 0.16666666666
				y3 = y0 - 1.0 + 3.0 * 0.16666666666
				z3 = z0 - 1.0 + 3.0 * 0.16666666666

				ii = i & 255
				jj = j & 255
				kk = k & 255

				g1 = __perm_mod12_lut[__perm_lut[ii + __perm_lut[jj + __perm_lut[kk + 1] + 1] + 1] + 1] * 3
				g2 = __perm_mod12_lut[__perm_lut[ii + i1 + __perm_lut[jj + j1 + __perm_lut[kk + k1 + 1] + 1] + 1] + 1] * 3
				g3 = __perm_mod12_lut[__perm_lut[ii + i2 + __perm_lut[jj + j2 + __perm_lut[kk + k2 + 1] + 1] + 1] + 1] * 3
				g4 = __perm_mod12_lut[__perm_lut[ii + 1 + __perm_lut[jj + 1 + __perm_lut[kk + 2] + 1] + 1] + 1] * 3

				t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
				t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
				t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
				t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3

			if(t0 < 0) n0 = 0.0
			else
				t0 *= t0
				n0 = t0 * t0 * (__grad3_lut[g1 + 1] * x0 + __grad3_lut[g1 + 2] * y0 + __grad3_lut[g1 + 3] * z0)

			if(t1 < 0) n1 = 0.0
			else
				t1 *= t1
				n1 = t1 * t1 * (__grad3_lut[g2 + 1] * x1 + __grad3_lut[g2 + 2] * y1 + __grad3_lut[g2 + 3] * z1)

			if(t2 < 0) n2 = 0.0
			else
				t2 *= t2
				n2 = t2 * t2 * (__grad3_lut[g3 + 1] * x2 + __grad3_lut[g3 + 2] * y2 + __grad3_lut[g3 + 3] * z2)

			if(t3 < 0) n3 = 0.0
			else
				t3 *= t3
				n3 = t3 * t3 * (__grad3_lut[g4 + 1] * x3 + __grad3_lut[g4 + 2] * y3 + __grad3_lut[g4 + 3] * z3)

			return 32.0 * (n0 + n1 + n2 + n3)

var
	list/__grad2_lut = list(1, 1, -1, 1, 1, -1, -1, -1, 1, 0, -1, 0, 1, 0, -1, 0, 0, 1, 0, -1, 0, 1, 0, -1)
	list/__grad3_lut = list(1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1, 0, 1, 0, 1, -1, 0, 1, 1, 0, -1, -1, 0, -1, 0, 1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1)

	list/__perm_lut = list(
	151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142,
	8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117,
	35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
	134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41,
	55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89,
	18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
	250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
	189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43,
	172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97,
	228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239,
	107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
	138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180,
	151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142,
	8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117,
	35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71,
	134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41,
	55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89,
	18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
	250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
	189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43,
	172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97,
	228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239,
	107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
	138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180)

	list/__perm_mod12_lut = list(
	7, 4, 5, 7, 6, 3, 11, 1, 9, 11, 0, 5, 2, 5, 7, 9, 8, 0, 7, 6, 9,
	10, 8, 3, 1, 0, 9, 10, 11, 10, 6, 4, 7, 0, 6, 3, 0, 2, 5, 2, 10,
	0, 3, 11, 9, 11, 11, 8, 9, 9, 9, 4, 9, 5, 8, 3, 6, 8, 5, 4, 3,
	0, 8, 7, 2, 9, 11, 2, 7, 0, 3, 10, 5, 2, 2, 3, 11, 3, 1, 2, 0,
	7, 1, 2, 4, 9, 8, 5, 7, 10, 5, 4, 4, 6, 11, 6, 5, 1, 3, 5, 1,
	0, 8, 1, 5, 4, 0, 7, 4, 5, 6, 1, 8, 4, 3, 10, 8, 8, 3, 2, 8, 4,
	1, 6, 5, 6, 3, 4, 4, 1, 10, 10, 4, 3, 5, 10, 2, 3, 10, 6, 3,
	10, 1, 8, 3, 2, 11, 11, 11, 4, 10, 5, 2, 9, 4, 6, 7, 3, 2, 9,
	11, 8, 8, 2, 8, 10, 7, 10, 5, 9, 5, 11, 11, 7, 4, 9, 9, 10, 3,
	1, 7, 2, 0, 2, 7, 5, 8, 4, 10, 5, 4, 8, 2, 6, 1, 0, 11, 10, 2,
	1, 10, 6, 0, 0, 11, 11, 6, 1, 9, 3, 1, 7, 9, 2, 11, 11, 1, 0,
	10, 7, 1, 7, 10, 1, 4, 0, 0, 8, 7, 1, 2, 9, 7, 4, 6, 2, 6, 8,
	1, 9, 6, 6, 7, 5, 0, 0, 3, 9, 8, 3, 6, 6, 11, 1, 0, 0, 7, 4, 5,
	7, 6, 3, 11, 1, 9, 11, 0, 5, 2, 5, 7, 9, 8, 0, 7, 6, 9, 10, 8,
	3, 1, 0, 9, 10, 11, 10, 6, 4, 7, 0, 6, 3, 0, 2, 5, 2, 10, 0, 3,
	11, 9, 11, 11, 8, 9, 9, 9, 4, 9, 5, 8, 3, 6, 8, 5, 4, 3, 0, 8,
	7, 2, 9, 11, 2, 7, 0, 3, 10, 5, 2, 2, 3, 11, 3, 1, 2, 0, 7, 1,
	2, 4, 9, 8, 5, 7, 10, 5, 4, 4, 6, 11, 6, 5, 1, 3, 5, 1, 0, 8,
	1, 5, 4, 0, 7, 4, 5, 6, 1, 8, 4, 3, 10, 8, 8, 3, 2, 8, 4, 1, 6,
	5, 6, 3, 4, 4, 1, 10, 10, 4, 3, 5, 10, 2, 3, 10, 6, 3, 10, 1,
	8, 3, 2, 11, 11, 11, 4, 10, 5, 2, 9, 4, 6, 7, 3, 2, 9, 11, 8,
	8, 2, 8, 10, 7, 10, 5, 9, 5, 11, 11, 7, 4, 9, 9, 10, 3, 1, 7, 2,
	0, 2, 7, 5, 8, 4, 10, 5, 4, 8, 2, 6, 1, 0, 11, 10, 2, 1, 10, 6,
	0, 0, 11, 11, 6, 1, 9, 3, 1, 7, 9, 2, 11, 11, 1, 0, 10, 7, 1,
	7, 10, 1, 4, 0, 0, 8, 7, 1, 2, 9, 7, 4, 6, 2, 6, 8, 1, 9, 6, 6,
	7, 5, 0, 0, 3, 9, 8, 3, 6, 6, 11, 1, 0, 0)