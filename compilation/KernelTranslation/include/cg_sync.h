#ifndef __CG_SYNC_H__
#define __CG_SYNC_H__

#include <string>

bool isCGThreadBlockSync(const std::string &FuncNameStr);

bool isCGThreadGroupSync(const std::string &FuncNameStr);

bool isCGSync(const std::string &name);

bool isWarpSync(const std::string &FuncNameStr);

#endif // __CG_SYNC_H__