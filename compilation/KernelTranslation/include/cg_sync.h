#ifndef __CG_SYNC_H__
#define __CG_SYNC_H__

#include <string>

bool isCGThreadBlockSync(const std::string &FuncNameStr);

bool isThreadGroupSync(const std::string &FuncNameStr);

bool isCGSync(const std::string &name);

#endif // __CG_SYNC_H__