package fi.jkauppa.javabinaryneuralnetwork;

import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.util.zip.Deflater;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.imageio.ImageIO;

public class TpmImage {
	private static final int tiledim = 16;
	private static final int tilesize = tiledim*tiledim;
	private static final int tilergb = tilesize*3;
	private static final float[][] tpmencode = new float[tilergb][tilergb];
	static { loadMatrix(tpmencode, "res/tpm/tpm.bin"); }

	private float[][] image = null;
	private float[] mean = null;
	private float scale = 1;
	private int[] props = {0,0,0,0,0,0,0,0,0};
	
	public TpmImage() {}
	
	public void compressImage(BufferedImage img, String filenameout, int components) {
		File outputfile = new File(filenameout);
		try {
			int imgwidth = img.getWidth();
			int imgheight = img.getHeight();
			int tilex = (int)Math.ceil((float)imgwidth/(float)tiledim);
			int tiley = (int)Math.ceil((float)imgheight/(float)tiledim);
			int tilesmp = tilex*tiley;
			float[][] img2 = new float[tilergb][tilesmp];
			for (int y=0;y<tiley;y++) {
				for (int x=0;x<tilex;x++) {
					for (int j=0;j<tiledim;j++) {
						for (int i=0;i<tiledim;i++) {
							int pixely = y*tiledim+j;
							int pixelx = x*tiledim+i;
							int pixelcolor = 0;
							if ((pixelx<imgwidth)&&(pixely<imgheight)) {
								pixelcolor = img.getRGB(pixelx, pixely);
							}
							int svdy = i*tiledim+j;
							int svdx = y*tilex+x;
							img2[tilesize*0+svdy][svdx] = (pixelcolor>>16) & 0xff;
							img2[tilesize*1+svdy][svdx] = (pixelcolor>>8) & 0xff;
							img2[tilesize*2+svdy][svdx] = pixelcolor & 0xff;
						}
					}
				}
			}
			float[] imgmean = new float[tilergb];
			matrixmean(imgmean, img2, tilergb);
			float[][] imgcentered = new float[tilergb][tilesmp];
			matrixsubtract(imgcentered, img2, imgmean, tilergb);
			float[][] imgbb = new float[components][tilesmp];
			matrixmultiply(imgbb, tpmencode, imgcentered, components);
			float imgsc = 128 / Math.max(Math.abs(matrixmax(imgbb, components)),Math.abs(matrixmin(imgbb, components)));
			float[][] imgbbs = new float[components][tilesmp];
			matrixscale(imgbbs, imgbb, imgsc, components);
			
			byte[] bbytes = new byte[4];
			ByteBuffer bfloat = ByteBuffer.wrap(bbytes);
			FloatBuffer cfloat = bfloat.asFloatBuffer();
			IntBuffer ifloat = bfloat.asIntBuffer();
			
			ZipOutputStream zipoutput = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outputfile)));
			zipoutput.setLevel(Deflater.BEST_COMPRESSION);
			ZipEntry zipimagetpm = new ZipEntry("image.tpm");
			zipoutput.putNextEntry(zipimagetpm);
			for (int i=0;i<tilesmp;i++) {
				for (int j=0;j<components;j++) {
					float fpval = imgbbs[j][i];
					float intval = (float)(Math.log(Math.abs(fpval))*13.19035d+64.0d);
					if (intval<0.0f) { intval = 0; }
					intval = Math.copySign(intval,fpval);
					zipoutput.write((byte)intval);
				}
			}
			zipoutput.closeEntry();

			ZipEntry zipmeantpm = new ZipEntry("mean.tpm");
			zipoutput.putNextEntry(zipmeantpm);
			for (int j=0;j<tilergb;j++) {
				cfloat.put(0, imgmean[j]);
				zipoutput.write(bbytes);
			}
			zipoutput.closeEntry();
			
			ZipEntry zipproptpm = new ZipEntry("prop.tpm");
			zipoutput.putNextEntry(zipproptpm);
			cfloat.put(0, imgsc); zipoutput.write(bbytes);
			ifloat.put(0, components); zipoutput.write(bbytes);
			ifloat.put(0, imgwidth); zipoutput.write(bbytes);
			ifloat.put(0, imgheight); zipoutput.write(bbytes);
			ifloat.put(0, tiledim); zipoutput.write(bbytes);
			ifloat.put(0, tilesize); zipoutput.write(bbytes);
			ifloat.put(0, tilergb); zipoutput.write(bbytes);
			ifloat.put(0, tilex); zipoutput.write(bbytes);
			ifloat.put(0, tiley); zipoutput.write(bbytes);
			ifloat.put(0, tilesmp); zipoutput.write(bbytes);
			zipoutput.closeEntry();
			
			zipoutput.close();
		} catch (Exception e) {e.printStackTrace();}
	}
	public BufferedImage extractImage(String filenamein, int components) {
		return null;
	}

	public static void main(String[] args) {
		System.out.println("init.");
		if (args.length<2) {
			System.out.println("arguments expected: filein.jpg fileout.tpm [compress=1]");
			return;
		}
		String filein = args[0];
		String fileout = args[1];
		boolean compress = true;
		int components = tilergb;
		if (args.length>=3) { compress = args[2].equals("1"); }
		if (args.length>=4) { components = Integer.parseInt(args[3]);}
		TpmImage tpmimage = new TpmImage();
		if (compress) {
			BufferedImage img = loadImage(filein);
			tpmimage.compressImage(img, fileout, components);
		} else {
			
		}
		System.out.println("exit.");
	}

	public static float matrixmax(float[][] a, int y) {
		float m = Float.NEGATIVE_INFINITY;
		for (int j=0;j<y;j++) {
			for (int i=0;i<a[0].length;i++) {
				if (a[j][i]>m) {
					m = a[j][i];
				}
			}
		}
		return m;
	}
	public static float matrixmin(float[][] a, int y) {
		float m = Float.POSITIVE_INFINITY;
		for (int j=0;j<y;j++) {
			for (int i=0;i<a[0].length;i++) {
				if (a[j][i]<m) {
					m = a[j][i];
				}
			}
		}
		return m;
	}
	public static void matrixmean(float[] c, float[][] a, int y) {
		for (int j=0;j<y;j++) {
			float m = 0;
			for (int i=0;i<a[0].length;i++) {
				m += a[j][i];
			}
			c[j] = m / a[0].length;
		}
	}
	
	public static void matrixscale(float[][] c, float[][] a, float b, int y) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<a[0].length;i++) {
				c[j][i] = a[j][i] * b;
			}
		}
	}
	public static void matrixsubtract(float[][] c, float[][] a, float[] b, int y) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<a[0].length;i++) {
				c[j][i] = a[j][i] - b[j];
			}
		}
	}
	public static void matrixmultiply(float[][] c, float[][] a, float[][] b, int y) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<b[0].length;i++) {
				float m = 0;
				for (int n=0;(n<a[0].length)&&(n<b.length);n++) {
					m += a[j][n] * b[n][i];
				}
				c[j][i] = m;
			}
		}
	}

	public static BufferedImage loadImage(String filenamein) {
		BufferedImage img = null;
		File inputfile = new File(filenamein);
		try {
			img = ImageIO.read(inputfile);
		} catch (Exception e) {e.printStackTrace();}
		return img;
	}
	public static void loadMatrix(float[][] matrix, String filename) {
		byte[] tpmbin = loadBinary(filename, true);
		ByteBuffer tpmbytes = ByteBuffer.wrap(tpmbin);
		FloatBuffer tpmfloats = tpmbytes.asFloatBuffer();
		for (int i=0;i<matrix.length;i++) {
			tpmfloats.get(matrix[i], 0, matrix.length);
		}
	}
	public static byte[] loadBinary(String filename, boolean loadresourcefromjar) {
		byte[] k = null;
		if (filename!=null) {
			try {
				File binaryfile = new File(filename);
				BufferedInputStream binaryfilestream = null;
				if (loadresourcefromjar) {
					binaryfilestream = new BufferedInputStream(ClassLoader.getSystemClassLoader().getResourceAsStream(binaryfile.getPath().replace(File.separatorChar, '/')));
				}else {
					binaryfilestream = new BufferedInputStream(new FileInputStream(binaryfile));
				}
				byte[] binarybytes = new byte[binaryfilestream.available()];
				DataInputStream dataInputStream = new DataInputStream(binaryfilestream);
				dataInputStream.readFully(binarybytes);
				k = binarybytes;
				binaryfilestream.close();
			} catch (Exception ex) {ex.printStackTrace();}
		}
		return k;
	}
	
}
