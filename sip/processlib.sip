%Module processlib 0

%ModuleHeaderCode
extern "C" { void processlib_import_array();}
%End

%PostInitialisationCode
processlib_import_array();
%End

struct Data
{
%TypeHeaderCode
#include <Data.h>
%End
  int frameNumber;
  void *buffer;
%GetCode
if(!sipCpp->buffer || !sipCpp->buffer->data)
   return Py_None;

npy_intp dims[] = {sipCpp->height,sipCpp->width};

switch(sipCpp->type)
{
  case Data::UINT8: sipPy = PyArray_SimpleNew(2,dims,NPY_UBYTE);break;
  case Data::INT8: sipPy = PyArray_SimpleNew(2,dims,NPY_BYTE);break;
  case Data::UINT16: sipPy = PyArray_SimpleNew(2,dims,NPY_USHORT);break;
  case Data::INT16: sipPy = PyArray_SimpleNew(2,dims,NPY_SHORT);break;
  case Data::UINT32: sipPy = PyArray_SimpleNew(2,dims,NPY_UINT);break;
  case Data::INT32: sipPy = PyArray_SimpleNew(2,dims,NPY_INT32);break;
  case Data::FLOAT: sipPy = PyArray_SimpleNew(2,dims,NPY_FLOAT32);break;
  case Data::DOUBLE: sipPy = PyArray_SimpleNew(2,dims,NPY_DOUBLE);break;
  default: return NULL; //Not yet managed
}
memcpy(((PyArrayObject*)sipPy)->data,sipCpp->buffer->data,
	sipCpp->size());
%End
%SetCode
PyArrayObject *tmpObject = (PyArrayObject*)PyArray_ContiguousFromObject(sipPy,NPY_NOTYPE,0,0);
if(!tmpObject) return NULL; //should throw an error
int nbDim = PyArray_NDIM(tmpObject);
if(nbDim > 2) return NULL;
int width,height;
height =  PyArray_DIM(tmpObject,0);
if(nbDim < 2) width = 1;
else width = PyArray_DIM(tmpObject,1);

switch(tmpObject->descr->type_num)
{
  case NPY_BYTE:
	sipCpp->type = Data::INT8;break;
  case NPY_UBYTE:
	sipCpp->type = Data::UINT8;break;
  case NPY_SHORT:
	sipCpp->type = Data::INT16;break;
  case NPY_USHORT:
        sipCpp->type = Data::UINT16;break;
  case NPY_INT32:
	sipCpp->type = Data::INT32;break;
  case NPY_UINT:
        sipCpp->type = Data::UINT32;break;
  case NPY_FLOAT32:
	sipCpp->type = Data::FLOAT;break;
  case NPY_DOUBLE:
	sipCpp->type = Data::DOUBLE;break;
  default:
        return NULL;
}
sipCpp->width = width,sipCpp->height = height;
int aSize = sipCpp->size();
Buffer *aNewBuffer = new Buffer(aSize);
memcpy(aNewBuffer->data,PyArray_DATA(tmpObject),aSize);
Py_DECREF(tmpObject);
sipCpp->setBuffer(aNewBuffer);
aNewBuffer->unref();
%End

%TypeCode
#define PY_ARRAY_UNIQUE_SYMBOL _ProcessLibNumpyArray
#include "numpy/arrayobject.h"
#include <iostream>
using namespace std;
extern "C"
{
  void processlib_import_array()
  {
    import_array();
  }
}
%End
  SIP_PYOBJECT refcount();
%MethodCode
  sipRes = PyLong_FromLong(sipCpp->buffer ? sipCpp->buffer->refcount : 0);
%End
};



class Task
{
%TypeHeaderCode
#include <Task.h>
%End
 public:
  Task(bool = true);
  virtual Data process(Data&);
  void setProcessingInPlace(bool);
  virtual Task* copy();
};

class TaskMgr
{
%TypeHeaderCode
#include <TaskMgr.h>
%End
public:
  TaskMgr();
  TaskMgr(const TaskMgr&);
  ~TaskMgr();

  void addTask(int aStage,Task *);
  void setInputData(Data &);
  void syncProcess();
};

class PoolThreadMgr
{
%TypeHeaderCode
#include <PoolThreadMgr.h>
%End

 public:
  enum SyncMode {Sequential,Parallel};
  static PoolThreadMgr& get() throw();
  
  void addProcess(TaskMgr *,bool = true);
  void removeProcess(TaskMgr *,bool = true);
  void setNumberOfThread(int);
  void setQueueLimit(int);
  int  queueLimit();
  void setTaskMgr(const TaskMgr *,SyncMode);
  long backgroundProcessMgrAddress(SyncMode);
  void quit();
};