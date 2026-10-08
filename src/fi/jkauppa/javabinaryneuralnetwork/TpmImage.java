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
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.FileImageOutputStream;

public class TpmImage {
	public static final int tpmtiledim = 16;
	public static final int tpmtilesize = tpmtiledim*tpmtiledim;
	public static final int tpmtilergb = tpmtilesize*3;
	public static final Matrix tpmencode = new Matrix(tpmtilergb,tpmtilergb);
	public static final Matrix tpmdecode = new Matrix(tpmtilergb,tpmtilergb);
	static {
		loadMatrix(tpmencode, "res/tpm/tpm.bin");
		matrixtranspose(tpmdecode, tpmencode);
	}

	protected byte[] tpmdata = null;
	protected byte[] tpmmean = null;
	protected float tpmscale = 1;
	protected int tpmcomps = 0;
	protected int tpmwidth = 0;
	protected int tpmheight = 0;
	protected int tpmtilex = 0;
	protected int tpmtiley = 0;
	protected int tpmtilesmp = 0;
	
	public TpmImage() {}
	
	public void compressImage(BufferedImage img, int components) {
		tpmcomps = components;
		tpmwidth = img.getWidth();
		tpmheight = img.getHeight();
		tpmtilex = (int)Math.ceil((float)tpmwidth/(float)tpmtiledim);
		tpmtiley = (int)Math.ceil((float)tpmheight/(float)tpmtiledim);
		tpmtilesmp = tpmtilex*tpmtiley;
		Matrix img2 = new Matrix(tpmtilergb,tpmtilesmp);
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
						img2.set(tpmtilesize*0+svdy,svdx,(pixelcolor>>16)&0xff);
						img2.set(tpmtilesize*1+svdy,svdx,(pixelcolor>>8)&0xff);
						img2.set(tpmtilesize*2+svdy,svdx,pixelcolor&0xff);
					}
				}
			}
		}
		Matrix imgmean = new Matrix(tpmtilesmp,3);
		matrixmean(imgmean, img2, tpmtilesize, 3);
		tpmmean = new byte[tpmtilesmp*3];
		for ( int i=0;i<tpmmean.length;i++) {
			tpmmean[i] = (byte)((int)imgmean.v[i]);
		}
		Matrix imgcentered = new Matrix(tpmtilergb,tpmtilesmp);
		matrixsubtract(imgcentered, img2, imgmean, tpmtilesize, 3);
		Matrix imgbb = new Matrix(tpmcomps,tpmtilesmp);
		matrixmultiply(imgbb, tpmencode, imgcentered, tpmtilesmp, tpmcomps);
		tpmscale = 128 / Math.max(Math.abs(matrixmax(imgbb, tpmcomps)),Math.abs(matrixmin(imgbb, tpmcomps)));
		Matrix imgbbs = new Matrix(tpmcomps,tpmtilesmp);
		matrixscale(imgbbs, imgbb, tpmscale, tpmcomps);
		
		tpmdata = new byte[tpmcomps*tpmtilesmp];
		for (int i=0;i<tpmtilesmp;i++) {
			for (int j=0;j<tpmcomps;j++) {
				tpmdata[i*tpmcomps+j] = (byte)imgbbs.get(j,i);
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
			zipoutput.write(tpmmean);
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
	public void readImage(String filenamein) {
		File inputfile = new File(filenamein);
		try {
			ZipFile zipfile = new ZipFile(inputfile);
			
			ZipEntry zipimagetpm = zipfile.getEntry("image.tpm");
			BufferedInputStream zipimageinput = new BufferedInputStream(zipfile.getInputStream(zipimagetpm));
			tpmdata = new byte[zipimageinput.available()];
			DataInputStream zipimagestream = new DataInputStream(zipimageinput);
			zipimagestream.readFully(tpmdata);

			ZipEntry zipmeantpm = zipfile.getEntry("mean.tpm");
			BufferedInputStream zipmeaninput = new BufferedInputStream(zipfile.getInputStream(zipmeantpm));
			tpmmean = new byte[zipmeaninput.available()];
			DataInputStream zipmeanstream = new DataInputStream(zipmeaninput);
			zipmeanstream.readFully(tpmmean);
			
			ZipEntry zipproptpm = zipfile.getEntry("prop.tpm");
			BufferedInputStream zippropinput = new BufferedInputStream(zipfile.getInputStream(zipproptpm));
			byte[] propbytes = new byte[zippropinput.available()];
			DataInputStream zippropstream = new DataInputStream(zippropinput);
			zippropstream.readFully(propbytes);
			ByteBuffer propbytebuffer = ByteBuffer.wrap(propbytes);
			FloatBuffer propfloatbuffer = propbytebuffer.asFloatBuffer();
			IntBuffer propintbuffer = propbytebuffer.asIntBuffer();
			tpmscale = propfloatbuffer.get();
			propintbuffer.position(1);
			tpmcomps = propintbuffer.get();
			tpmwidth = propintbuffer.get();
			tpmheight = propintbuffer.get();
			propintbuffer.position(7);
			tpmtilex = propintbuffer.get();
			tpmtiley = propintbuffer.get();
			tpmtilesmp = propintbuffer.get();
			
			zipfile.close();
		} catch (Exception e) {e.printStackTrace();}
	}
	public BufferedImage extractImage(int components) {
		int tpmcomponents = tpmcomps;
		if (components<tpmcomponents) {
			tpmcomponents = components;
		}
		Matrix imgbb = new Matrix(tpmcomponents,tpmtilesmp);
		for (int i=0;i<tpmtilesmp;i++) {
			for (int j=0;j<tpmcomponents;j++) {
				imgbb.set(j,i,(1.0f/tpmscale)*(float)tpmdata[i*tpmcomps+j]);
			}
		}
		Matrix imgcentered = new Matrix(tpmtilergb,tpmtilesmp);
		matrixmultiply(imgcentered, tpmdecode, imgbb, tpmtilesmp, tpmtilergb);
		Matrix imgmean = new Matrix(tpmtilesmp,3);
		for (int i=0;i<tpmmean.length;i++) {
			imgmean.v[i] = (float)(Byte.toUnsignedInt(tpmmean[i]));
		}
		Matrix img2 = new Matrix(tpmtilergb,tpmtilesmp);
		matrixaddition(img2, imgcentered, imgmean, tpmtilesize, 3);

		BufferedImage img = new BufferedImage(tpmwidth, tpmheight, BufferedImage.TYPE_3BYTE_BGR);
		for (int y=0;y<tpmtiley;y++) {
			for (int x=0;x<tpmtilex;x++) {
				for (int j=0;j<tpmtiledim;j++) {
					for (int i=0;i<tpmtiledim;i++) {
						int pixely = y*tpmtiledim+j;
						int pixelx = x*tpmtiledim+i;
						int svdy = i*tpmtiledim+j;
						int svdx = y*tpmtilex+x;
						int pixelred = (int)(img2.get(tpmtilesize*0+svdy,svdx));
						int pixelgreen = (int)(img2.get(tpmtilesize*1+svdy,svdx));
						int pixelblue = (int)(img2.get(tpmtilesize*2+svdy,svdx));
						pixelred = (pixelred>255)?255:((pixelred<0)?0:pixelred);
						pixelgreen = (pixelgreen>255)?255:((pixelgreen<0)?0:pixelgreen);
						pixelblue = (pixelblue>255)?255:((pixelblue<0)?0:pixelblue);
						int pixelcolor = (pixelred<<16) | (pixelgreen<<8) | pixelblue;
						if ((pixelx<tpmwidth)&&(pixely<tpmheight)) {
							img.setRGB(pixelx, pixely, pixelcolor);
						}
					}
				}
			}
		}
		return img;
	}

	public static void main(String[] args) {
		System.out.println("init.");
		if (args.length<2) {
			System.out.println("arguments expected: filein.jpg fileout.tpm [compress=1] [components=768]");
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
			tpmimage.readImage(filein);
			BufferedImage img = tpmimage.extractImage(components);
			saveImage(fileout, img, 1.0f);
		}
		System.out.println("exit.");
	}

	public static float matrixmax(Matrix a, int y) {
		float m = Float.NEGATIVE_INFINITY;
		for (int j=0;j<y;j++) {
			for (int i=0;i<a.w;i++) {
				if (a.get(j,i)>m) {
					m = a.get(j,i);
				}
			}
		}
		return m;
	}
	public static float matrixmin(Matrix a, int y) {
		float m = Float.POSITIVE_INFINITY;
		for (int j=0;j<y;j++) {
			for (int i=0;i<a.w;i++) {
				if (a.get(j,i)<m) {
					m = a.get(j,i);
				}
			}
		}
		return m;
	}
	public static void matrixmean(Matrix c, Matrix a, int y, int s) {
		for (int k=0;k<s;k++) {
			for (int i=0;i<a.w;i++) {
				float m = 0;
				for (int j=y*k;j<(y*(k+1));j++) {
					m += a.get(j,i);
				}
				c.set(k,i,m/(float)y);
			}
		}
	}
	public static void matrixaddition(Matrix c, Matrix a, Matrix b, int y, int s) {
		for (int k=0;k<s;k++) {
			for (int i=0;i<a.w;i++) {
				for (int j=y*k;j<(y*(k+1));j++) {
					c.set(j,i,a.get(j,i)+b.get(k,i));
				}
			}
		}
	}
	public static void matrixsubtract(Matrix c, Matrix a, Matrix b, int y, int s) {
		for (int k=0;k<s;k++) {
			for (int i=0;i<a.w;i++) {
				for (int j=y*k;j<(y*(k+1));j++) {
					c.set(j,i,a.get(j,i)-b.get(k,i));
				}
			}
		}
	}
	public static void matrixscale(Matrix c, Matrix a, float b, int y) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<a.w;i++) {
				c.set(j,i,a.get(j,i)*b);
			}
		}
	}
	public static void matrixmultiply(Matrix c, Matrix a, Matrix b, int x, int y) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<b.w;i++) {
				float m = 0;
				for (int n=0;(n<x)&&(n<a.w)&&(n<b.h);n++) {
					m += a.get(j,n) * b.get(n,i);
				}
				c.set(j,i,m);
			}
		}
	}
	public static void matrixtranspose(Matrix c, Matrix a) {
		for (int j=0;j<a.h;j++) {
			for (int i=0;i<a.w;i++) {
				c.set(j,i,a.get(i,j));
			}
		}
	}

	public static void saveImage(String filenameout, BufferedImage img, float quality) {
		File outputfile = new File(filenameout);
		try {
			ImageWriter jpegWriter = ImageIO.getImageWritersByFormatName("JPEG").next();
			ImageWriteParam jpegParams = jpegWriter.getDefaultWriteParam();
			jpegParams.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
			jpegParams.setCompressionQuality(quality);
			FileImageOutputStream outputfilestream = new FileImageOutputStream(outputfile);
			jpegWriter.setOutput(outputfilestream);
			IIOImage outputImage = new IIOImage(img, null, null);
			jpegWriter.write(null, outputImage, jpegParams);
			jpegWriter.dispose();
		} catch (Exception e) {e.printStackTrace();}
	}
	public static BufferedImage loadImage(String filenamein) {
		BufferedImage img = null;
		File inputfile = new File(filenamein);
		try {
			img = ImageIO.read(inputfile);
		} catch (Exception e) {e.printStackTrace();}
		return img;
	}
	public static void loadMatrix(Matrix matrix, String filename) {
		byte[] tpmbin = loadBinary(filename, true);
		ByteBuffer tpmbytes = ByteBuffer.wrap(tpmbin);
		FloatBuffer tpmfloats = tpmbytes.asFloatBuffer();
		tpmfloats.get(matrix.v, 0, matrix.v.length);
	}
	public static String loadText(String filename, boolean loadresourcefromjar) {
		return new String(loadBinary(filename, loadresourcefromjar));
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
	
	public static class Matrix {
		public float[] v = null;
		public int w = 0;
		public int h = 0;
		public Matrix() {}
		public Matrix(int ih, int iw) {
			h = ih;
			w = iw;
			v = new float[ih*iw];
		}
		public float get(int y, int x) {
			return v[y*w+x];
		}
		public void set(int y, int x, float d) {
			v[y*w+x] = d;
		}
	}
}
