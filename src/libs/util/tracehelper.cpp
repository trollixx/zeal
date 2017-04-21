#include "tracehelper.h"

TraceHelper::TraceHelper(const char *method, const char *message) :
    m_method(method),
    m_message(message)
{
    m_timer.start();
    if (m_message)
        qDebug("> %s [%s]", m_method, m_message);
    else
        qDebug("> %s", m_method);
}

TraceHelper::~TraceHelper()
{
    if (m_message)
        qDebug("< %s [%s] (elapsed %lld ms)", m_method, m_message, m_timer.elapsed());
    else
        qDebug("< %s (elapsed %lld ms)", m_method, m_timer.elapsed());
}

