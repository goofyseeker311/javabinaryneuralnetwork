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
	private static final int tpmtiledim = 16;
	private static final int tpmtilesize = tpmtiledim*tpmtiledim;
	private static final int tpmtilergb = tpmtilesize*3;
	private static final float[][] tpmencode = new float[tpmtilergb][tpmtilergb];
	static { loadMatrix(tpmencode, "res/tpm/tpm.bin"); }

	private byte[] tpmdata = null;
	private float[] tpmmean = null;
	private float tpmscale = 1;
	private int tpmcomps = 0;
	private int tpmwidth = 0;
	private int tpmheight = 0;
	private int tpmtilex = 0;
	private int tpmtiley = 0;
	private int tpmtilesmp = 0;
	
	public TpmImage() {}
	
	public void compressImage(BufferedImage img, int components) {
		tpmcomps = components;
		tpmwidth = img.getWidth();
		tpmheight = img.getHeight();
		tpmtilex = (int)Math.ceil((float)tpmwidth/(float)tpmtiledim);
		tpmtiley = (int)Math.ceil((float)tpmheight/(float)tpmtiledim);
		tpmtilesmp = tpmtilex*tpmtiley;
		float[][] img2 = new float[tpmtilergb][tpmtilesmp];
		for (int y=0;y<tpmtiley;y++) {
			for (int x=0;x<tpmtilex;x++) {
				for (int j=0;j<tpmtiledim;j++) {
					for (int i=0;i<tpmtiledim;i++) {
						int pixely = y*tpmtiledim+j;
						int pixelx = x*tpmtiledim+i;
						int pixelcolor = 0;
						if ((pixelx<tpmwidth)&&(pixely<tpmheight)) {
							pixelcolor = img.getRGB(pixelx, pixely);
						}
						int svdy = i*tpmtiledim+j;
						int svdx = y*tpmtilex+x;
						img2[tpmtilesize*0+svdy][svdx] = (pixelcolor>>16) & 0xff;
						img2[tpmtilesize*1+svdy][svdx] = (pixelcolor>>8) & 0xff;
						img2[tpmtilesize*2+svdy][svdx] = pixelcolor & 0xff;
					}
				}
			}
		}
		tpmmean = new float[tpmtilergb];
		matrixmean(tpmmean, img2, tpmtilergb);
		float[][] imgcentered = new float[tpmtilergb][tpmtilesmp];
		matrixsubtract(imgcentered, img2, tpmmean, tpmtilergb);
		float[][] imgbb = new float[tpmcomps][tpmtilesmp];
		matrixmultiply(imgbb, tpmencode, imgcentered, tpmcomps);
		tpmscale = 128 / Math.max(Math.abs(matrixmax(imgbb, tpmcomps)),Math.abs(matrixmin(imgbb, tpmcomps)));
		float[][] imgbbs = new float[tpmcomps][tpmtilesmp];
		matrixscale(imgbbs, imgbb, tpmscale, tpmcomps);
		
		tpmdata = new byte[tpmcomps*tpmtilesmp];
		for (int i=0;i<tpmtilesmp;i++) {
			for (int j=0;j<tpmcomps;j++) {
				float fpval = imgbbs[j][i];
				float intval = (float)(Math.log(Math.abs(fpval))*13.19035d+64.0d);
				if (intval<0.0f) { intval = 0; }
				intval = Math.copySign(intval,fpval);
				tpmdata[i*tpmcomps+j] = (byte)intval;
			}
		}
	}
	public void writeImage(String filenameout) {
		File outputfile = new File(filenameout);
		try {
			ZipOutputStream zipoutput = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outputfile)));
			zipoutput.setLevel(Deflater.BEST_COMPRESSION);

			byte[] bbytes = new byte[4];
			ByteBuffer bfloat = ByteBuffer.wrap(bbytes);
			FloatBuffer cfloat = bfloat.asFloatBuffer();
			IntBuffer ifloat = bfloat.asIntBuffer();
			
			ZipEntry zipimagetpm = new ZipEntry("image.tpm");
			zipoutput.putNextEntry(zipimagetpm);
			zipoutput.write(tpmdata);
			zipoutput.closeEntry();

			ZipEntry zipmeantpm = new ZipEntry("mean.tpm");
			zipoutput.putNextEntry(zipmeantpm);
			for (int j=0;j<tpmtilergb;j++) {
				cfloat.put(0, tpmmean[j]);
				zipoutput.write(bbytes);
			}
			zipoutput.closeEntry();
			
			ZipEntry zipproptpm = new ZipEntry("prop.tpm");
			zipoutput.putNextEntry(zipproptpm);
			cfloat.put(0, tpmscale); zipoutput.write(bbytes);
			ifloat.put(0, tpmcomps); zipoutput.write(bbytes);
			ifloat.put(0, tpmwidth); zipoutput.write(bbytes);
			ifloat.put(0, tpmheight); zipoutput.write(bbytes);
			ifloat.put(0, tpmtiledim); zipoutput.write(bbytes);
			ifloat.put(0, tpmtilesize); zipoutput.write(bbytes);
			ifloat.put(0, tpmtilergb); zipoutput.write(bbytes);
			ifloat.put(0, tpmtilex); zipoutput.write(bbytes);
			ifloat.put(0, tpmtiley); zipoutput.write(bbytes);
			ifloat.put(0, tpmtilesmp); zipoutput.write(bbytes);
			zipoutput.closeEntry();
			
			zipoutput.close();
		} catch (Exception e) {e.printStackTrace();}
	}
	public BufferedImage extractImage(String filenamein, int components) {
		return null;
	}
	public void readImage(String filenamein) {
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
		int components = tpmtilergb;
		if (args.length>=3) { compress = args[2].equals("1"); }
		if (args.length>=4) { components = Integer.parseInt(args[3]);}
		TpmImage tpmimage = new TpmImage();
		if (compress) {
			BufferedImage img = loadImage(filein);
			tpmimage.compressImage(img, components);
			tpmimage.writeImage(fileout);
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
