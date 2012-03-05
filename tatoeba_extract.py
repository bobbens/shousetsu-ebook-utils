#!/usr/bin/env python
# -*- coding: utf-8 -*-


import csv
import sys
import random


# http://tatoeba.org/files/downloads/sentences.csv
# http://tatoeba.org/files/downloads/links.csv
file_sentences = "sentences.csv"
file_links     = "links.csv"
file_output    = "tatoeba.csv"


# Load Sentences
fp_sentences = open( file_sentences, "rb" )
sentences    = csv.reader( fp_sentences, delimiter='\t' )
jpn_dict = {}
eng_dict = {}
for row in sentences:
   entry_id   = int( row[0] )
   entry_lang = row[1]
   entry_data = row[2]
   if entry_lang == 'eng':
      eng_dict[ entry_id ] = entry_data
   elif entry_lang == 'jpn':
      jpn_dict[ entry_id ] = entry_data
fp_sentences.close()
print( "ENG dict: %d" % len( eng_dict ) )
print( "JPN dict: %d" % len( jpn_dict ) )

# Load links
fp_links = open( file_links, "rb" )
links    = csv.reader( fp_links, delimiter='\t' )
lnk_dict = {}
for row in links:
   entry_id     = int( row[0] )
   entry_target = int( row[1] )
   lnk_dict[ entry_id ] = entry_target
fp_links.close()

# Create the sentence look up
jpn_eng_dict = {}
for jpn_id, jpn_data in jpn_dict.items():
   try:
      eng_id = lnk_dict[ jpn_id ]
      jpn_eng_dict[ jpn_data ] = eng_dict[ eng_id ]
   except:
      continue
      #print "Unexpected error:", sys.exc_info()[0]
print( "JPN-ENG dict: %d" % len( jpn_eng_dict ) )

# Randomly shuffle and access
keys = jpn_eng_dict.keys()
random.shuffle( keys )
fp_output = open( file_output, "wb" )
output = csv.writer( fp_output, delimiter='\t' )
i = 0
for jpn_data in keys:
   eng_data = jpn_eng_dict[ jpn_data ]
   output.writerow( [ jpn_data, eng_data ] )
   i = i+1
fp_output.close()
print( "Wrote %d rows to %s" % (i, file_output ) )


