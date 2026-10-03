package fi.jkauppa.javabinaryneuralnetwork;

import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.util.TreeMap;

import org.lwjgl.BufferUtils;
import org.lwjgl.PointerBuffer;
import org.lwjgl.glfw.GLFWNativeGLX;
import org.lwjgl.glfw.GLFWNativeWGL;
import org.lwjgl.glfw.GLFWNativeX11;
import org.lwjgl.opencl.APPLEGLSharing;
import org.lwjgl.opencl.CL;
import org.lwjgl.opencl.CL30;
import org.lwjgl.opencl.CL12GL;
import org.lwjgl.opencl.CLCapabilities;
import org.lwjgl.opencl.CLContextCallback;
import org.lwjgl.opencl.KHRGLSharing;
import org.lwjgl.opengl.CGL;
import org.lwjgl.opengl.WGL;
import org.lwjgl.system.MemoryStack;
import org.lwjgl.system.MemoryUtil;
import org.lwjgl.system.Platform;

public class ComputeLib {
	public TreeMap<Long,Device> devicemap = null;
	public Long[] devicelist = null;

	public ComputeLib() {
		this(MemoryUtil.NULL);
	}
	public ComputeLib(long window) {
		this.devicemap = initClDevices(window);
		devicelist = devicemap.keySet().toArray(new Long[devicemap.size()]);
		for (int i=0;i<devicelist.length;i++) {
			long device = devicelist[i];
			Device devicedata = devicemap.get(device);
			System.out.print("OpenCL device["+i+"]: "+devicedata.devicename+" ["+devicedata.plaformopenclversion+"]");
			if (devicedata.platformcontextsharing) {
				System.out.print(" (OpenGL context sharing supported)");
			}
			System.out.println();
		}
	}

	public void writeBufferf(long device, long queue, long vmem, float[] v) {
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueWriteBuffer(queue, vmem, true, 0, v, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}
	public void writeBufferi(long device, long queue, long vmem, int[] v) {
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueWriteBuffer(queue, vmem, true, 0, v, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}

	public void readBufferf(long device, long queue, long vmem, float[] v) {
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueReadBuffer(queue, vmem, true, 0, v, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}
	public void readBufferi(long device, long queue, long vmem, int[] v) {
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueReadBuffer(queue, vmem, true, 0, v, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}

	public void fillBufferf(long vmem, long queue, float fill, int size) {
		MemoryStack clStack = MemoryStack.stackPush();
		ByteBuffer pattern = clStack.malloc(4);
		pattern.putFloat(fill);
		pattern.rewind();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueFillBuffer(queue, vmem, pattern, 0, size*4, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}
	public void fillBufferi(long vmem, long queue, int fill, int size) {
		MemoryStack clStack = MemoryStack.stackPush();
		ByteBuffer pattern = clStack.malloc(4);
		pattern.putInt(fill);
		pattern.rewind();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueFillBuffer(queue, vmem, pattern, 0, size*4, null, event);
		CL30.clWaitForEvents(event);
		MemoryStack.stackPop();
	}

	public long createQueue(long device) {
		MemoryStack clStack = MemoryStack.stackPush();
		Device devicedata = devicemap.get(device);
		long context = devicedata.context;
		IntBuffer errcode_ret = clStack.callocInt(1);
		long queue = CL30.clCreateCommandQueue(context, device, CL30.CL_QUEUE_PROFILING_ENABLE, errcode_ret);
		MemoryStack.stackPop();
		return queue;
	}
	public void waitForQueue(long queue) {
		CL30.clFinish(queue);
	}
	public void insertBarrier(long queue) {
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer event = clStack.mallocPointer(1);
		CL30.clEnqueueBarrierWithWaitList(queue, null, event);
		MemoryStack.stackPop();
	}

	public long createBuffer(long device, int size) {
		MemoryStack clStack = MemoryStack.stackPush();
		Device devicedata = devicemap.get(device);
		long context = devicedata.context;
		IntBuffer errcode_ret = clStack.callocInt(1);
		long buffer = CL30.clCreateBuffer(context, CL30.CL_MEM_READ_WRITE, size*4, errcode_ret);
		MemoryStack.stackPop();
		return buffer;
	}
	public void removeBuffer(long vmem) {
		CL30.clReleaseMemObject(vmem);
	}

	public long createSharedGLBuffer(long device, int glbuffer) {
		MemoryStack clStack = MemoryStack.stackPush();
		IntBuffer errcode_ret = clStack.callocInt(1);
		Device devicedata = devicemap.get(device);
		long context = devicedata.context;
		long buffer = CL12GL.clCreateFromGLBuffer(context, CL30.CL_MEM_READ_WRITE, glbuffer, errcode_ret);
		MemoryStack.stackPop();
		return buffer;
	}
	public void acquireSharedGLBuffer(long queue, long vmem) {
		CL12GL.clEnqueueAcquireGLObjects(queue, vmem, null, null);
	}
	public void releaseSharedGLBuffer(long queue, long vmem) {
		CL12GL.clEnqueueReleaseGLObjects(queue, vmem, null, null);
	}

	public long compileProgram(long device, String source) {
		long program = MemoryUtil.NULL;
		MemoryStack clStack = MemoryStack.stackPush();
		Device devicedata = devicemap.get(device);
		long context = devicedata.context;
		IntBuffer errcode_ret = clStack.callocInt(1);
		program = CL30.clCreateProgramWithSource(context, source, errcode_ret);
		if (CL30.clBuildProgram(program, device, "-cl-std=CL2.0 -Werror", null, MemoryUtil.NULL)!=CL30.CL_SUCCESS) {
			String buildinfo = getClProgramBuildInfo(program, device, CL30.CL_PROGRAM_BUILD_LOG);
			System.out.println("compileProgram build failed:");
			System.out.println(buildinfo);
		}
		MemoryStack.stackPop();
		return program;
	}
	public void runProgram(long device, long queue, long program, String entry, long[] fmem, int[] offset, int[] size) {
		MemoryStack clStack = MemoryStack.stackPush();
		IntBuffer errcode_ret = clStack.callocInt(1);
		long kernel = CL30.clCreateKernel(program, entry, errcode_ret);
		int kernel_error_int = errcode_ret.get(errcode_ret.position());
		if (kernel_error_int==CL30.CL_SUCCESS) {
			for (int i=0;i<fmem.length;i++) {
				CL30.clSetKernelArg1p(kernel, i, fmem[i]);
			}
			int dimensions = offset.length; if (size.length<dimensions) {dimensions = size.length;}
			PointerBuffer globalWorkOffset = BufferUtils.createPointerBuffer(dimensions);
			PointerBuffer globalWorkSize = BufferUtils.createPointerBuffer(dimensions);
			PointerBuffer localWorkSize = null;
			for (int i=0;i<dimensions;i++) {
				globalWorkOffset.put(i, offset[i]);
				globalWorkSize.put(i, size[i]);
			}
			PointerBuffer event = clStack.mallocPointer(1);
			kernel_error_int = CL30.clEnqueueNDRangeKernel(queue, kernel, dimensions, globalWorkOffset, globalWorkSize, localWorkSize, null, event);
			if (kernel_error_int!=CL30.CL_SUCCESS) {
				System.out.print("runProgram kernel enqueue failed: "+kernel_error_int+" ");
				if (kernel_error_int==CL30.CL_INVALID_PROGRAM_EXECUTABLE) {
					System.out.print("INVALID_PROGRAM_EXECUTABLE");
				} else if (kernel_error_int==CL30.CL_INVALID_COMMAND_QUEUE) {
					System.out.print("INVALID_COMMAND_QUEUE");
				} else if (kernel_error_int==CL30.CL_INVALID_CONTEXT) {
					System.out.print("INVALID_CONTEX");
				} else if (kernel_error_int==CL30.CL_INVALID_KERNEL_ARGS) {
					System.out.print("INVALID_KERNEL_ARGS");
				} else if (kernel_error_int==CL30.CL_INVALID_WORK_DIMENSION) {
					System.out.print("INVALID_WORK_DIMENSION");
				} else if (kernel_error_int==CL30.CL_INVALID_GLOBAL_WORK_SIZE) {
					System.out.print("INVALID_GLOBAL_WORK_SIZE");
				} else if (kernel_error_int==CL30.CL_INVALID_GLOBAL_OFFSET) {
					System.out.print("INVALID_GLOBAL_OFFSET");
				} else if (kernel_error_int==CL30.CL_INVALID_WORK_GROUP_SIZE) {
					System.out.print("INVALID_WORK_GROUP_SIZE");
				} else if (kernel_error_int==CL30.CL_INVALID_WORK_ITEM_SIZE) {
					System.out.print("INVALID_WORK_ITEM_SIZE");
				} else if (kernel_error_int==CL30.CL_MISALIGNED_SUB_BUFFER_OFFSET) {
					System.out.print("MISALIGNED_SUB_BUFFER_OFFSET");
				} else if (kernel_error_int==CL30.CL_INVALID_IMAGE_SIZE) {
					System.out.print("INVALID_IMAGE_SIZE");
				} else if (kernel_error_int==CL30.CL_IMAGE_FORMAT_NOT_SUPPORTED) {
					System.out.print("IMAGE_FORMAT_NOT_SUPPORTED");
				} else if (kernel_error_int==CL30.CL_OUT_OF_RESOURCES) {
					System.out.print("OUT_OF_RESOURCES");
				} else if (kernel_error_int==CL30.CL_MEM_OBJECT_ALLOCATION_FAILURE) {
					System.out.print("MEM_OBJECT_ALLOCATION_FAILURE");
				} else if (kernel_error_int==CL30.CL_INVALID_EVENT_WAIT_LIST) {
					System.out.print("INVALID_EVENT_WAIT_LIST");
				} else if (kernel_error_int==CL30.CL_OUT_OF_HOST_MEMORY) {
					System.out.print("OUT_OF_HOST_MEMORY");
				} else {
					System.out.print("unknown error.");
				}
				System.out.println();
			}
		}
		MemoryStack.stackPop();
	}

	public static class Device {
		public long platform = MemoryUtil.NULL;
		public long context = MemoryUtil.NULL;
		public long queue = MemoryUtil.NULL;
		public String platformname = null;
		public CLCapabilities plaformcaps = null;
		public String plaformopenclversion = null;
		public boolean platformcontextsharing = false;
		public String devicename = null;
	}

	private TreeMap<Long,Device> initClDevices(long window) {
		TreeMap<Long,Device> devicesinit = new TreeMap<Long,Device>();
		MemoryStack clStack = MemoryStack.stackPush();
		IntBuffer pi = clStack.mallocInt(1);
		if (CL30.clGetPlatformIDs(null, pi)==CL30.CL_SUCCESS) {
			PointerBuffer clPlatforms = clStack.mallocPointer(pi.get(0));
			if (CL30.clGetPlatformIDs(clPlatforms, (IntBuffer)null)==CL30.CL_SUCCESS) {
				for (int p = 0; p < clPlatforms.capacity(); p++) {
					long platform = clPlatforms.get(p);
					CLCapabilities platformcaps = CL.createPlatformCapabilities(platform);
					IntBuffer pi2 = clStack.mallocInt(1);
					if (CL30.clGetDeviceIDs(platform, CL30.CL_DEVICE_TYPE_ALL, null, pi2)==CL30.CL_SUCCESS) {
						PointerBuffer clDevices = clStack.mallocPointer(pi2.get(0));
						if (CL30.clGetDeviceIDs(platform, CL30.CL_DEVICE_TYPE_ALL, clDevices, (IntBuffer)null)==CL30.CL_SUCCESS) {
							for (int d = 0; d < clDevices.capacity(); d++) {
								long device = clDevices.get(d);

								IntBuffer errcode_ret = clStack.callocInt(1);
								int errcode_ret_int = 1;
								boolean contextsharing = false;
								long context = MemoryUtil.NULL;
								if (window!=MemoryUtil.NULL) {
									PointerBuffer clCtxPropsSharing = clStack.mallocPointer(7);
									switch (Platform.get()) {
									case WINDOWS: clCtxPropsSharing.put(KHRGLSharing.CL_GL_CONTEXT_KHR).put(GLFWNativeWGL.glfwGetWGLContext(window)).put(KHRGLSharing.CL_WGL_HDC_KHR).put(WGL.wglGetCurrentDC()); break;
									case FREEBSD:
									case LINUX: clCtxPropsSharing.put(KHRGLSharing.CL_GL_CONTEXT_KHR).put(GLFWNativeGLX.glfwGetGLXContext(window)).put(KHRGLSharing.CL_GLX_DISPLAY_KHR).put(GLFWNativeX11.glfwGetX11Display()); break;
									case MACOSX: clCtxPropsSharing.put(APPLEGLSharing.CL_CONTEXT_PROPERTY_USE_CGL_SHAREGROUP_APPLE).put(CGL.CGLGetShareGroup(CGL.CGLGetCurrentContext()));
									}
									clCtxPropsSharing.put(CL30.CL_CONTEXT_PLATFORM).put(platform).put(MemoryUtil.NULL).flip();
									context = CL30.clCreateContext(clCtxPropsSharing, device, (CLContextCallback)null, MemoryUtil.NULL, errcode_ret);
									errcode_ret_int = errcode_ret.get(errcode_ret.position());
									if (errcode_ret_int==CL30.CL_SUCCESS) {
										contextsharing = true;
									}
								}

								if (errcode_ret_int!=CL30.CL_SUCCESS) {
									PointerBuffer clCtxProps = clStack.mallocPointer(3);
									clCtxProps.put(0, CL30.CL_CONTEXT_PLATFORM).put(1, platform).put(2, 0);
									context = CL30.clCreateContext(clCtxProps, device, (CLContextCallback)null, MemoryUtil.NULL, errcode_ret);
								}

								errcode_ret_int = errcode_ret.get(errcode_ret.position());
								if (errcode_ret_int==CL30.CL_SUCCESS) {
									Device devicedesc = new Device();
									devicedesc.platform = platform;
									devicedesc.context = context;
									devicedesc.queue = CL30.clCreateCommandQueue(context, device, CL30.CL_QUEUE_PROFILING_ENABLE, (IntBuffer)null);
									devicedesc.platformname = getClPlatformInfo(platform, CL30.CL_PLATFORM_NAME).trim();
									devicedesc.plaformcaps = platformcaps;
									devicedesc.plaformopenclversion = getClPlatformInfo(platform, CL30.CL_PLATFORM_VERSION).trim();
									devicedesc.devicename = getClDeviceInfo(device, CL30.CL_DEVICE_NAME).trim();
									devicedesc.platformcontextsharing = contextsharing;
									devicesinit.put(device, devicedesc);
								}
							}
						}
					}
				}
			}
		}
		MemoryStack.stackPop();
		return devicesinit;
	}

	private String getClPlatformInfo(long platform, int param) {
		String platforminfo = null;
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer pp = clStack.mallocPointer(1);
		if (CL30.clGetPlatformInfo(platform, param, (ByteBuffer)null, pp)==CL30.CL_SUCCESS) {
			int bytes = (int)pp.get(0);
			ByteBuffer buffer = clStack.malloc(bytes);
			if (CL30.clGetPlatformInfo(platform, param, buffer, null)==CL30.CL_SUCCESS) {
				platforminfo = MemoryUtil.memUTF8(buffer, bytes - 1);
			}
		}
		MemoryStack.stackPop();
		return platforminfo;
	}

	private String getClDeviceInfo(long device, int param) {
		String deviceinfo = null;
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer pp = clStack.mallocPointer(1);
		if (CL30.clGetDeviceInfo(device, param, (ByteBuffer)null, pp)==CL30.CL_SUCCESS) {
			int bytes = (int)pp.get(0);
			ByteBuffer buffer = clStack.malloc(bytes);
			if (CL30.clGetDeviceInfo(device, param, buffer, null)==CL30.CL_SUCCESS) {
				deviceinfo = MemoryUtil.memUTF8(buffer, bytes - 1);
			}
		}
		MemoryStack.stackPop();
		return deviceinfo;
	}

	private String getClProgramBuildInfo(long program, long device, int param) {
		String buildinfo = null;
		MemoryStack clStack = MemoryStack.stackPush();
		PointerBuffer pp = clStack.mallocPointer(1);
		if (CL30.clGetProgramBuildInfo(program, device, param, (ByteBuffer)null, pp)==CL30.CL_SUCCESS) {
			int bytes = (int)pp.get(0);
			ByteBuffer buffer = clStack.malloc(bytes);
			if (CL30.clGetProgramBuildInfo(program, device, param, buffer, pp)==CL30.CL_SUCCESS) {
				buildinfo = MemoryUtil.memUTF8(buffer, bytes - 1);
			}
		}
		MemoryStack.stackPop();
		return buildinfo;
	}
}
