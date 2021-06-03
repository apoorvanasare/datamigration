create or replace PACKAGE DV_REPORTS
AS

    PROCEDURE EXECUTE_DV ;
	PROCEDURE GENERATE_REPO;
	PROCEDURE GENERATE_REPORT (pcSAVE_DATA char := 'N');


END;
/


create or replace PACKAGE BODY DV_REPORTS
AS

report_date       date := SYSDATE;

PROCEDURE EXECUTE_DV AS


   CURSOR exec_dv is
   SELECT  nvl(GROUP_ID,0) GROUP_ID,AZURE_TABLE
    FROM  DATA_MAPPING_CONFIG  where group_id=1;


BEGIN

	FOR exec_rec in exec_dv LOOP

    dbms_output.put_line(exec_rec.AZURE_TABLE);
	DATA_MAPPING_CONFIG ('N',NULL,exec_rec.AZURE_TABLE,exec_rec.GROUP_ID);

	END LOOP;

END;     

PROCEDURE GENERATE_REPO AS

   CURSOR get_diff is
    SELECT distinct UPDATED, ERR_MSG,LAST_RUN,AZURE_TABLE, LEGACY_COUNT,AZURE_COUNT,LEGACY_OGG_DIFF,AZURE_OGG_DIFF, 
	DBMS_LOB.substr(AZURE_QUERY,3000) as query_1, DBMS_LOB.substr(LEGACY_QUERY,3000) as query_2,EXECUTIONTIMEINSECS as EXECTIME,GROUP_ID
	FROM  DATA_MAPPING_CONFIG 
    WHERE (LEGACY_OGG_DIFF >0 OR AZURE_OGG_DIFF>0) or (LEGACY_OGG_DIFF =0 OR AZURE_OGG_DIFF=0);

BEGIN

	GEN_EXCEL.START_WORKSHEET('OGG_difference');
	GEN_EXCEL.FORMAT_WORKSHEET(pnFREEZE_PANE_ROW=>8, pbADD_HEADER=>FALSE);
	
	GEN_EXCEL.START_NAMES;
	GEN_EXCEL.CREATE_NAME('Print_Area', '=OGG_difference');
	GEN_EXCEL.CREATE_NAME('_FilterDatabase', '=R8C1:R8C10');
	GEN_EXCEL.CREATE_NAME('Print_Titles', '=R1:R8');
	GEN_EXCEL.FINISH_NAMES;
	
	GEN_EXCEL.CREATE_AUTOFILTER(8, 8, 10);
	
	GEN_EXCEL.START_TABLE;
	
	GEN_EXCEL.DEFINE_COLUMN(1, 22.57);
	GEN_EXCEL.DEFINE_COLUMN(2, 22.14);
	GEN_EXCEL.DEFINE_COLUMN(3, 22.00);
	GEN_EXCEL.DEFINE_COLUMN(4, 22.00);
	GEN_EXCEL.DEFINE_COLUMN(5, 22.43);
	GEN_EXCEL.DEFINE_COLUMN(6, 22.57);
	GEN_EXCEL.DEFINE_COLUMN(7, 22.14);
	GEN_EXCEL.DEFINE_COLUMN(8, 22.29);
	GEN_EXCEL.DEFINE_COLUMN(9, 22.00);
	GEN_EXCEL.DEFINE_COLUMN(10, 22.00);
	GEN_EXCEL.DEFINE_COLUMN(11, 22.57);
	GEN_EXCEL.DEFINE_COLUMN(12, 22.00);

	GEN_EXCEL.APPEND_TEXT('');
	
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textb', TRUE, TRUE, 1, 'Report Run Date: ' || TO_CHAR(report_date, 'DD-MON-YYYY HH24:MI:SS'), psNAME=>'Print_Area');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textb', TRUE, TRUE, 1, 'OGG  Report', psNAME=>'Print_Area');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textb', TRUE, TRUE, 1, 'For DIfference ', psNAME=>'Print_Area');
	GEN_EXCEL.APPEND_TEXT('');
	GEN_EXCEL.MERGE_CELLS(1, 1, 10);
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textcb12', TRUE, TRUE, 1, 'OGG Data Difference Report');
	GEN_EXCEL.APPEND_TEXT('');
	
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', TRUE, FALSE, 1, 'UPDATED', pnROW_HEIGHT=>63.0, psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 2, 'ERR_MSG', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 3, 'LAST_RUN', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 4, 'AZURE_TABLE', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 5, 'LEGACY_COUNT', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 6, 'AZURE_COUNT', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 7, ' LEGACY_OGG_DIFF', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 8, 'AZURE_OGG_DIFF', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, FALSE, 9, 'query_1', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, TRUE, 10, 'query_2', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, TRUE, 11, 'EXECTIME', psNAME=>'_FilterDatabase');
	GEN_EXCEL.APPEND_TEXT_WITH_STYLE('heading', FALSE, TRUE, 12, 'GROUP_ID', psNAME=>'_FilterDatabase');


    FOR diff_rec in get_diff LOOP
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdLeft', TRUE, FALSE, 1, diff_rec.UPDATED, pnROW_HEIGHT=>12.75);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdLeft', FALSE, FALSE, 2, diff_rec.ERR_MSG);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 3, diff_rec.LAST_RUN);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 4, diff_rec.AZURE_TABLE);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 5, diff_rec.LEGACY_COUNT); 
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 6, diff_rec.AZURE_COUNT);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 7, diff_rec.LEGACY_OGG_DIFF);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 8, diff_rec.AZURE_OGG_DIFF);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdCenter', FALSE, FALSE, 9, diff_rec.query_1);
		GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdLeft', FALSE, TRUE, 10, diff_rec.query_2);
	    GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdLeft', FALSE, TRUE, 11, diff_rec.EXECTIME);
	    GEN_EXCEL.APPEND_TEXT_WITH_STYLE('textbrdLeft', FALSE, TRUE, 12, diff_rec.GROUP_ID);

    END LOOP;

GEN_EXCEL.END_WORKSHEET(TRUE);

END;




PROCEDURE GENERATE_REPORT (pcSAVE_DATA char := 'N') AS

    ora_instance   varchar2(20);
    recipient      varchar2(1000); 

BEGIN



GEN_EXCEL.START_DOCUMENT;

GEN_EXCEL.START_STYLES;
GEN_EXCEL.CREATE_STYLE('text', 'Left', FALSE);
GEN_EXCEL.CREATE_STYLE('textb', 'Left', FALSE, pbBOLD=>TRUE);
GEN_EXCEL.CREATE_STYLE('textw', 'Left', TRUE);
GEN_EXCEL.CREATE_STYLE('textcb12', 'Center', FALSE, pnFONT_SIZE=> 12, pbBOLD=>TRUE);

GEN_EXCEL.CREATE_STYLE('heading', 'Center', TRUE, pnROTATION=>45, pbBORDERS=>TRUE, pbBOLD=>TRUE);

GEN_EXCEL.CREATE_STYLE('textbrdLeft', 'Left', FALSE, pbBORDERS=>TRUE);
GEN_EXCEL.CREATE_STYLE('textbrdCenter', 'Center', FALSE, pbBORDERS=>TRUE);
GEN_EXCEL.CREATE_STYLE('textbrdRight', 'Right', FALSE, pbBORDERS=>TRUE);

GEN_EXCEL.CREATE_STYLE('textbrdc', 'Center', FALSE, pbBORDERS=>TRUE);
GEN_EXCEL.CREATE_STYLE('textc', 'Center', FALSE);

GEN_EXCEL.FINISH_STYLES;

	EXECUTE_DV;


    GENERATE_REPO;



GEN_EXCEL.END_DOCUMENT;

    select UPPER(sys_context('USERENV','DB_NAME'))
      into ora_instance
      from dual;

    IF ora_instance = '<DB_Instance>' THEN
       recipient := '<email_id>';
    ELSE
       recipient := '<email_id>';
    END IF;

    -- Email the report
GEN_EXCEL.Send_Mail(recipient, ' Data Validation',
        'Please see the attached Data Validation Report from the ' || UPPER(ora_instance) || ' instance',
       'OGG_report.xlsx', GEN_EXCEL.GET_DOCUMENT(pcSAVE_DATA));

END;


END;
/