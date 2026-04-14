#ifndef SQLITE_VEC_H
#define SQLITE_VEC_H

#include <sqlite3.h>

#ifdef __cplusplus
extern "C" {
#endif

int sqlite3_vec_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi);

#ifdef __cplusplus
}
#endif

#endif
