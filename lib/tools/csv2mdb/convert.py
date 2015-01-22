# encoding: utf-8
#-*- coding: utf8 -*-
#usage: wine $PY27/python.exe /media/sf_debian_wrkspace/test_csv.py > b.txt
#import csv <== this extension has problem to support unicode!
import sys
import win32com.client
import codecs
import shutil

csvCount = 0
connection = win32com.client.Dispatch(r'ADODB.Connection')
recordset = win32com.client.Dispatch(r'ADODB.Recordset')
# CSV reader
def insertDB():
	global csvCount
	print "... 檔案轉換中 ..."
	with codecs.open('Z:\\src\\bin\\master_import.csv', 'r', encoding='cp950') as f:
		for line in f:
			csvCount += 1
			w = line.split(',')
			connection.Execute(u"""INSERT INTO t_Meibo(ID, Name) VALUES ({0}, '{1}')""".format(int(w[0]), w[1].strip()))

def checkRecordCount():
	recordset.Open('SELECT COUNT(*) from t_Meibo', connection, 1, 3)
	mdbCount = recordset.Fields.Item(0).Value
	print "原CSV檔案中資料量： ", csvCount
	print "現在主檔資料庫中資料量： ", mdbCount
	print "兩邊資料量是否相同： ", mdbCount == csvCount

def init():
	try:
		print "生成主檔(master.mdb)資料庫"
		shutil.copy2('Z:\\src\\bin\\master_temp.mdb','Z:\\src\\bin\\master.mdb')
	except IOError as (errno, strerror):
		print "I/O error({0}): {1}".format(errno, strerror)
	except:
		print "Unexpected error:", sys.exc_info()[0]
		raise

try:
	init()
	DSN = 'PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=Z:\\src\\bin\\master.mdb;Jet OLEDB:Database Password=perfectinsider'
	connection.Open(DSN)
	if connection.State == 1:
		print "已連接至主檔(master.mdb)資料庫"
		insertDB()
		checkRecordCount()
	else:
		print "連接至主檔(master.mdb)資料庫錯誤！"
except:
		print "轉檔錯誤請檢查原輸入檔為正確CSV格式並為中文（CP950）編碼，錯誤代碼: ", sys.exc_info()[0]
		raise
finally:
	# Close up the connection and unload the COM object
	if connection.State == 1: connection.Close()
	connection = None