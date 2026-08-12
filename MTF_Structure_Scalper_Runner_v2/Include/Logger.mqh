//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|      Lightweight leveled logger with optional file output         |
//+------------------------------------------------------------------+
#ifndef MTSR2_LOGGER_MQH
#define MTSR2_LOGGER_MQH

#include "Defs.mqh"

class CLogger
  {
private:
   ENUM_LOG_LEVEL    m_level;
   bool              m_to_file;
   int               m_fh;
   string            m_tag;

   string            LevelStr(ENUM_LOG_LEVEL lv) const
     {
      switch(lv)
        {
         case LOG_ERROR: return "ERR ";
         case LOG_WARN:  return "WARN";
         case LOG_INFO:  return "INFO";
         case LOG_DEBUG: return "DBG ";
        }
      return "----";
     }

public:
                     CLogger() { m_level=LOG_INFO; m_to_file=false; m_fh=INVALID_HANDLE; m_tag="MTSR2"; }
                    ~CLogger() { CloseFile(); }

   void              Init(ENUM_LOG_LEVEL lv,bool to_file,const string tag)
     {
      m_level=lv; m_tag=tag;
      if(to_file)
        {
         string fname=StringFormat("%s_%s.log",m_tag,TimeToString(TimeCurrent(),TIME_DATE));
         m_fh=FileOpen(fname,FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
         if(m_fh!=INVALID_HANDLE)
           {
            FileSeek(m_fh,0,SEEK_END);
            m_to_file=true;
           }
        }
     }

   void              SetLevel(ENUM_LOG_LEVEL lv) { m_level=lv; }

   void              CloseFile()
     {
      if(m_fh!=INVALID_HANDLE) { FileClose(m_fh); m_fh=INVALID_HANDLE; }
      m_to_file=false;
     }

   void              Write(ENUM_LOG_LEVEL lv,const string msg)
     {
      if(lv>m_level) return;
      string line=StringFormat("%s | %s | %s",
                               TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                               LevelStr(lv),msg);
      Print(line);
      if(m_to_file && m_fh!=INVALID_HANDLE)
        {
         FileWriteString(m_fh,line+"\r\n");
         FileFlush(m_fh);
        }
     }

   void              Error(const string m) { Write(LOG_ERROR,m); }
   void              Warn (const string m) { Write(LOG_WARN ,m); }
   void              Info (const string m) { Write(LOG_INFO ,m); }
   void              Debug(const string m) { Write(LOG_DEBUG,m); }
  };

#endif // MTSR2_LOGGER_MQH
//+------------------------------------------------------------------+
