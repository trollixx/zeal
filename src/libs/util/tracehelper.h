#ifndef TRACEHELPER_H
#define TRACEHELPER_H

#include <QElapsedTimer>
#include <QString>

/*
Based on https://github.com/jason-deng/C99FunctionOverload

Copyright (c) 2015, jason-deng
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of C99FunctionOverload nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#define TRACE_0() TraceHelper _trace_helper_(Q_FUNC_INFO)
#define TRACE_1(message) TraceHelper _trace_helper__(Q_FUNC_INFO, message)

#define FUNC_CHOOSER(_f1, _f2, ...) _f2
#define FUNC_RECOMPOSER(argsWithParentheses) FUNC_CHOOSER argsWithParentheses
#define CHOOSE_FROM_ARG_COUNT(...) FUNC_RECOMPOSER((__VA_ARGS__, TRACE_1, ))
#define NO_ARG_EXPANDER() ,TRACE_0
#define MACRO_CHOOSER(...) CHOOSE_FROM_ARG_COUNT(NO_ARG_EXPANDER __VA_ARGS__ ())
#define TRACE(...) MACRO_CHOOSER(__VA_ARGS__)(__VA_ARGS__)

class TraceHelper
{
public:
    TraceHelper(const char *method, const char *message = nullptr);
    ~TraceHelper();

private:
    const char *m_method = nullptr;
    const char *m_message = nullptr;
    QElapsedTimer m_timer;
};

#endif // TRACEHELPER_H
