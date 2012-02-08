#!/usr/local/bin/python
#! -*- coding: utf-8 -*-

import mx.ODBC.Manager

import md5 
import os
import sys
import string
import datetime
import shutil

from mikado.common.db import tdlib
import MOI_user_passwords
import ODI_objects_from_repo as odi_lib

'''
interactive playpen
'''


#fingerconn = tdlib.getConn(dsn=MOI_user_passwords.DSNSTRINGS['FINGERPRINT'])
conn = tdlib.getConn(dsn=MOI_user_passwords.get_dsn_details('$DBCONNREF'))


#str = "TERADATA_SOURCE_ERROR_MERGE"
#folder = r'C:\ODICodeForComparison\direct_compare_results\$DBCONNREF'
#for f in os.listdir(folder):
#    if f.find(str) >=0:
#        print f


sql = '''SELECT SCEN_NAME FROM moi_scen_sources
WHERE MAX_RUN_START_DATETIME < TO_DATE('2011-10-09', 'YYYY-MM-DD')'''

known_concerns = [
    'APPLICANT_GROUP_LITERATURE', 
'APP_GROUP_FUNDING_OPT_VALUES', 
'BATCH_LOAD', 
'BLD_CREDIT_BANDS', 
'BLD_EQF_FEEDBACK_DATA', 
'BLD_EQ_ADDRESS_DETAILS', 
'BLD_EQ_COMPANY_DETAILS', 
'BLD_EQ_CONTACT_DETAILS', 
'BLD_OFFICER_ROLL', 
'BLD_SIC_CODE', 
'BLD_YP_CLASS', 
'BLD_YP_COMPANY_STATUS', 
'BLD_YP_GROUP', 
'BLD_YP_PREMISES', 
'BLD_YP_SECTOR', 
'BUSINESS_OBJECT_FULFILMENTS', 
'CAMPAIGNS', 
'CHEQUE_REDIRECTION_RULES', 
'CLAIM_ACCUMULATORS', 
'COMPLAINT_FEEDBACK', 
'DOCUMENT_PACK_FULFILMENTS', 
'EXT_EQ_CONTACT_DETAILS', 
'GENX_SPEC_TIMELINES_AUD', 
'GL_JOURNAL', 
'IMT008M', 
'IMT_MEMBER_CROSSREFERENCE_IDS', 
'IMX_LOCATIONS', 
'IMX_MEMBER_CROSSREFERENCE_IDS', 
'INTERMEDIARY_ADHOC_PAYMENTS', 
'INTERMEDIARY_COMMISSION_HOLDS', 
'INTERMEDIARY_HIERARCHY', 
'ISC_BUNDLE_CONVERSION', 
'MARKETING_DELIVERY_PREFERENCES', 
'MCT010D', 
'MCT011D', 
'MCX_CSS_BASS_PATIENTS', 
'MCX_CSS_BASS_REGISTRATIONS', 
'MCX_CSS_CLAIMS', 
'MCX_CSS_CLAIM_DIAG_IMPAIRMENT', 
'MCX_CSS_CLAIM_ITEM_SETS', 
'MCX_CSS_CLAIM_LINES', 
'MCX_CSS_CLAIM_PROCEDURE_SERVS', 
'MCX_CSS_INVOICES', 
'MEMBER_REGISTRATIONS_AUD', 
'MET015D', 
'MEX_ERP_GROUP_TYPES', 
'MEX_ERP_SALESMAN_DETAILS', 
'MMX002', 
'MOID009D', 
'MOID013D', 
'MOID021D', 
'MOID202D', 
'MSXSWIFT_MEMBERS', 
'MUT002W', 
'MUT004', 
'OMT_ADDRESSES', 
'OMT_PROJECTS', 
'OMT_QUOTES', 
'OMT_REPORT549', 
'OMX_SWIFTTITLES', 
'ORGANISATION_EVENTS', 
'OTX003', 
'PKG_MOI_RECONCILATION', 
'PKG_SWIFT_RECONCILATION', 
'PROCEDURE_PRICING_VERSIONS_AUD', 
'PROCEDURE_PRIC_LIST_HIST_AUD', 
'PRODUCT_DEFINITIONS', 
'PROVIDERS_AUD', 
'PROVIDER_BUNDLE_IDENT_HIST_AUD', 
'PROVIDER_CONTRACTS_AUD', 
'PROVIDER_FACILITIES_AUD', 
'PROVIDER_NETWORK_DISC_AUD', 
'PST_JOURNAL_GEN_ACCOUNT_ENTRIES', 
'PSW004D', 
'PSX001D', 
'QUEUE_SQL_CONDITIONS', 
'QUOTES', 
'RMTDEPENDANT_PARTY_ROLES', 
'RMTDEPENDANT_PARTY_ROLE_ADDRESSES', 
'RMTGROUP_PARTIES', 
'RMTMEMBER_PARTY_ROLES', 
'RMTMEMBER_PARTY_ROLE_ADDRESSES', 
'RMX001', 
'RMXMEMBERRECEIPT', 
'SALES_ACTIVITIES', 
'SML050D', 
'SML099D', 
'SML106D', 
'SML114D', 
'SMT600', 
'SWIFT_SYSTEM_USER_DETAILS', 
'TASK_EVENT_PROGRESSIONS', 
'TAX_DUE', 
'USER_TEAM_CONTACTS', 

]



rs = tdlib.query2obj(conn, sql)
for row in rs:
    if row.SCEN_NAME in known_concerns:
        print "match", row.SCEN_NAME

        