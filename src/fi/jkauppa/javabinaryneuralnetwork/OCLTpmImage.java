package fi.jkauppa.javabinaryneuralnetwork;

import static org.lwjgl.system.MemoryUtil.NULL;

import java.awt.image.BufferedImage;

import fi.jkauppa.javabinaryneuralnetwork.ComputeLib.Device;

public class OCLTpmImage extends TpmImage {
	private ComputeLib computelib = null;
	private int selecteddevice = 0;
	private long opencldevice = NULL, openclqueue = NULL, openclprogram = NULL;
	private Device opencldevicedata = null;
	private String usingopencldevice = null;
	
	public OCLTpmImage() {
		this.selecteddevice = 0;
		this.computelib = new ComputeLib();
		this.opencldevice = this.computelib.devicelist[selecteddevice];
		this.opencldevicedata = this.computelib.devicemap.get(opencldevice);
		this.usingopencldevice = opencldevicedata.devicename;
		System.out.println("Using device["+selecteddevice+"]: "+usingopencldevice);
		this.openclqueue = opencldevicedata.queue;
		
		String programSource = loadText("res/tpm/tpm.cl", true);
		this.openclprogram = this.computelib.compileProgram(opencldevice, programSource);
	}
	
	@Override public void compressImage(BufferedImage img, int components) {
		tpmcomps = components;
		tpmwidth = img.getWidth();
		tpmheight = img.getHeight();
		tpmtilex = (int)Math.ceil((float)tpmwidth/(float)tpmtiledim);
		tpmtiley = (int)Math.ceil((float)tpmheight/(float)tpmtiledim);
		tpmtilesmp = tpmtilex*tpmtiley;
		
		//long imgparamsptr = computelib.createBuffer(opencldevice, imgparams.length);
		//computelib.writeBufferf(opencldevice, openclqueue, imgparamsptr, tpmencode);
		
		int imglength = tpmwidth*tpmheight*3;
		int img2length = tpmtilergb*tpmtilesmp/4;
		int[] imgparams = new int[]{tpmwidth, tpmheight, tpmtilex, tpmtiley};
		long imgparamsptr = computelib.createBuffer(opencldevice, imgparams.length);
		computelib.writeBufferi(opencldevice, openclqueue, imgparamsptr, imgparams);
		
		long imgptr = computelib.createBuffer(opencldevice, imglength);
		long img2ptr = computelib.createBuffer(opencldevice, img2length);
		int[] imgdata = new int[imglength];
		img.getData().getPixels(0, 0, tpmwidth, tpmheight, imgdata);
		computelib.writeBufferi(opencldevice, openclqueue, imgptr, imgdata);
		computelib.runProgram(opencldevice, openclqueue, openclprogram, "compressimage", new long[]{imgptr, imgparamsptr, img2ptr}, new int[]{0, 0}, new int[]{tpmtilex-1, tpmtiley-1});
		//float[] newgraphicsbuffer = new float[4];
		//computelib.readBufferf(opencldevice, openclqueue, graphicsbufferptr, newgraphicsbuffer);
		
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

	@Override public BufferedImage extractImage(int components) {
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
		TpmImage tpmimage = new OCLTpmImage();
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

}
