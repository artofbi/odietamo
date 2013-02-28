DECLARE 
	l_count					PLS_INTEGER := 0;
	l_create_table			BOOLEAN := FALSE;
	l_crt_main_ddl			VARCHAR(1000) := 'CREATE TABLE odiscm_controls'
						  || '('
						  || '  odi_user_name                  VARCHAR2(35) PRIMARY KEY'
						  || ', import_start_datetime          DATE'
						  || ', code_branch_name               VARCHAR(1000)'
						  || ', code_branch_last_import_rev    VARCHAR(1000)'
--------------------------|| ', import_in_progress_ind         CHAR(1) NOT NULL'
						  || ')';
	l_crt_scen_ddl			VARCHAR(1000) := 'CREATE TABLE odiscm_genscen_sources'
						  || '('
						  || '  source_object_id               INTEGER NOT NULL'
						  || ', source_type_id                 INTEGER NOT NULL'
						  || ', folder_id                      INTEGER NOT NULL'
						  || ', project_id                     INTEGER NOT NULL'
						  || ', marker_group_code              VARCHAR2(100)'
						  || ', CONSTRAINT osgs_pk PRIMARY KEY (source_object_id, source_type_id, marker_group_code)'
						  || ')';
	l_crt_master_flush_ddl	VARCHAR(1000) := 'CREATE TABLE odiscm_master_flush_controls'
						  || '('
						  || '  odi_user_name                  VARCHAR2(35) PRIMARY KEY'
						  || ', flush_from_datetime            DATE'
						  || ', flush_to_datetime              DATE'
						  || ', last_updated_by_command_name   VARCHAR2(500)'
						  || ')';
	l_crt_work_flush_ddl	VARCHAR(1000) := 'CREATE TABLE odiscm_work_flush_controls'
						  || '('
						  || '  odi_user_name                  VARCHAR2(35) PRIMARY KEY'
						  || ', flush_from_datetime            DATE'
						  || ', flush_to_datetime              DATE'
						  || ', last_updated_by_command_name   VARCHAR2(500)'
						  || ')';
	l_crt_work_link_ddl		VARCHAR(1000) := 'CREATE DATABASE LINK odiworkrep_data CONNECT TO <OdiWorkRepoUserName>'
						  || '  IDENTIFIED BY <OdiWorkRepoPassWord> USING ''<OdiWorkRepoConnectionString>''';
BEGIN
	SELECT COUNT(*)
	  INTO l_count
	  FROM user_tables
	 WHERE table_name = 'ODISCM_CONTROLS'
	;
	
	IF l_count = 0
	THEN
		BEGIN
			EXECUTE IMMEDIATE l_crt_main_ddl;
			EXECUTE IMMEDIATE 'ANALYZE TABLE odiscm_controls ESTIMATE STATISTICS';
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_application_error(-20000, 'Cannot create or analyse table ODISCM_CONTROLS');
		END;
	END IF;

	SELECT COUNT(*)
	  INTO l_count
	  FROM user_tables
	 WHERE table_name = 'ODISCM_GENSCEN_SOURCES'
	;

	IF l_count = 0
	THEN
		BEGIN
			EXECUTE IMMEDIATE l_crt_scen_ddl;
			EXECUTE IMMEDIATE 'ANALYZE TABLE odiscm_genscen_sources ESTIMATE STATISTICS';
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_application_error(-20000, 'Cannot create or analyse table ODISCM_GENSCEN_SOURCES');
		END;
	END IF;

	SELECT COUNT(*)
	  INTO l_count
	  FROM user_tables
	 WHERE table_name = 'ODISCM_MASTER_FLUSH_CONTROLS'
	;

	IF l_count = 0
	THEN
		BEGIN
			EXECUTE IMMEDIATE l_crt_master_flush_ddl;
			EXECUTE IMMEDIATE 'ANALYZE TABLE odiscm_master_flush_controls ESTIMATE STATISTICS';
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_application_error(-20000, 'Cannot create or analyse table ODISCM_MASTER_FLUSH_CONTROLS');
		END;
	END IF;
	
	SELECT COUNT(*)
	  INTO l_count
	  FROM user_tables
	 WHERE table_name = 'ODISCM_WORK_FLUSH_CONTROLS'
	;

	IF l_count = 0
	THEN
		BEGIN
			EXECUTE IMMEDIATE l_crt_work_flush_ddl;
			EXECUTE IMMEDIATE 'ANALYZE TABLE odiscm_work_flush_controls ESTIMATE STATISTICS';
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_application_error(-20000, 'Cannot create or analyse table ODISCM_WORK_FLUSH_CONTROLS');
		END;
	END IF;

	SELECT COUNT(*)
	  INTO l_count
	  FROM user_db_links
	 WHERE db_link LIKE 'ODIWORKREP_DATA%'		-- Allow for DB links created with domain suffixes.
	;
	
	IF l_count = 0
	THEN
		BEGIN
			EXECUTE IMMEDIATE l_crt_work_link_ddl;
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_application_error(-20000, 'Cannot create database link ODIWORKREP_DATA');
		END;
	END IF;

END;
/