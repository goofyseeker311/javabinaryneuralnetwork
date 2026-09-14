package fi.jkauppa.javabinaryneuralnetwork;

import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.imageio.ImageIO;

public class JavaBinaryNeuralNetwork {
	private int svddim = 768;
	private int tiledim = 16;
	private int tilesize = tiledim*tiledim;
	private int tilergb = tilesize*3;
	private float[][] tpmencode = new float[svddim][svddim];
	
	public JavaBinaryNeuralNetwork() {
		loadMatrix(tpmencode, "res/tpm/tpm.bin");
	}
	
	public void encode(String filenamein, String filenameout, boolean compress, int components) {
		System.out.println("run.");
		File inputfile = new File(filenamein);
		File outputfile = new File(filenameout);
		if (compress) {
			try {
				BufferedImage img = ImageIO.read(inputfile);
				int imgwidth = img.getWidth();
				int imgheight = img.getHeight();
				int tilex = (int)Math.ceil(imgwidth/tiledim);
				int tiley = (int)Math.ceil(imgheight/tiledim);
				int tilesmp = tilex*tiley;
				float[][] img2 = new float[tilergb][tilesmp];
				for (int y=0;y<tiley;y++) {
					for (int x=0;x<tilex;x++) {
						for (int j=0;j<tiledim;j++) {
							for (int i=0;i<tiledim;i++) {
								int pixely = y*tiledim+j;
								int pixelx = x*tiledim+i;
								int pixelcolor = img.getRGB(pixelx, pixely);
								int svdy = (i*tiledim+j)*3;
								int svdx = y*tilex+x;
								img2[svdy+0][svdx] = (byte)(pixelcolor&0xff);
								img2[svdy+1][svdx] = (byte)((pixelcolor>>8)&0xff);
								img2[svdy+2][svdx] = (byte)((pixelcolor>>16)&0xff);
							}
						}
					}
				}
				float[][] imgbb = new float[components][tilesmp];
				matrixmultiply(imgbb, tpmencode, img2, components, tilesmp);
				ZipOutputStream zipoutput = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outputfile)));
				ZipEntry zipimage = new ZipEntry(filenameout);
				zipoutput.putNextEntry(zipimage);
				byte[] bfloats = new byte[tilesmp*4];
				ByteBuffer bbuffer = ByteBuffer.wrap(bfloats);
				for (int i=0;i<components;i++) {
					bbuffer.asFloatBuffer().put(imgbb[i]).rewind();
					zipoutput.write(bfloats);
				}
				zipoutput.closeEntry();
				zipoutput.close();
			} catch (IOException e) {e.printStackTrace();}
		} else {
			
		}
		System.out.println("end.");
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
		int components = 768;
		if (args.length>=3) { compress = args[2].equals("1"); }
		if (args.length>=4) { components = Integer.parseInt(args[3]);}
		JavaBinaryNeuralNetwork jbnn = new JavaBinaryNeuralNetwork();
		jbnn.encode(filein, fileout, compress, components);
		System.out.println("exit.");
	}
	
	public static void matrixmultiply(float[][] c, float[][] a, float[][] b, int y, int x) {
		for (int j=0;j<y;j++) {
			for (int i=0;i<x;i++) {
				float m = 0;
				for (int n=0;(n<a[0].length)&&(n<b.length);n++) {
					m += a[j][n] * b[n][i];
				}
				c[j][i] = m;
			}
		}
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
