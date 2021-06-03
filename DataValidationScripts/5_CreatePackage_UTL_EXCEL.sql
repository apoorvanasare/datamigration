create or replace PACKAGE UTL_EXCEL AS
cXL_PAPER_LETTER constant number := 1;
cXL_PAPER_LEGAL  constant number := 5;
TYPE border_type IS RECORD
(sPosition     varchar2(6),
sLineStyle    varchar2(10) := 'Continuous',
nWeight       integer := 1);
TYPE border_array IS VARRAY(4) OF border_type;
PROCEDURE START_DOCUMENT (pnTAB_RATION integer:= null);
PROCEDURE END_DOCUMENT;
FUNCTION GET_CUR_COLUMN RETURN integer;
FUNCTION GET_CUR_ROW RETURN integer;
FUNCTION GET_DOCUMENT (pcKEEP_DATA char := 'N') RETURN clob;
PROCEDURE START_WORKSHEET (psWORKSHEET_NAME varchar2, pbPROTECT boolean := FALSE);
PROCEDURE END_WORKSHEET (pbADD_LEGAL_NOTE boolean := FALSE);
PROCEDURE FORMAT_WORKSHEET (psORIENTATION varchar2 := 'Landscape', pbFIT_TO_PAGE boolean := TRUE,
pbSINGLE_PAGE boolean := FALSE, plPAPER_SIZE number := cXL_PAPER_LETTER, pbADD_HEADER boolean := TRUE,
pnFREEZE_PANE_ROW number := null);
PROCEDURE START_NAMES;
PROCEDURE FINISH_NAMES;
PROCEDURE CREATE_NAME (psNAME varchar2, psRANGE varchar2 := null);
PROCEDURE CREATE_AUTOFILTER (pnSTART_ROW integer, pnEND_ROW integer, pnNUM_COLUMNS integer);
PROCEDURE START_STYLES;
PROCEDURE FINISH_STYLES;
PROCEDURE CREATE_STYLE (psSTYLE varchar2, psHORIZ_ALIGN varchar2, pbWRAP_TEXT boolean,
pnROTATION integer := 0, pbBORDERS boolean := FALSE, pnFONT_SIZE integer := 10,
pbBOLD boolean := FALSE, pbUNDERLINE boolean := FALSE, pbITALIC boolean := FALSE,
psNUMBER_FORMAT varchar2 := null, psFORE_COLOR_CODE varchar2 := null, psBACK_COLOR_CODE varchar2 := null);
PROCEDURE CREATE_STYLE (psSTYLE varchar2, psHORIZ_ALIGN varchar2, pbWRAP_TEXT boolean,
poBORDERS border_array, pnROTATION integer := 0, pnFONT_SIZE integer := 10,
pbBOLD boolean := FALSE, pbUNDERLINE boolean := FALSE, pbITALIC boolean := FALSE,
psNUMBER_FORMAT varchar2 := null, psFORE_COLOR_CODE varchar2 := null, psBACK_COLOR_CODE varchar2 := null);
PROCEDURE START_TABLE; 
PROCEDURE DEFINE_COLUMN (pnCOLUMN integer, pnWIDTH number);
PROCEDURE APPEND_TEXT (psTEXT varchar2, pnROW_HEIGHT number := null, psDATA_TYPE varchar2 := 'String',
psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null);
PROCEDURE APPEND_TEXT_WITH_STYLE (psSTYLE varchar2, pbSTART_ROW boolean, pbEND_ROW boolean,
pnSTART_COLUMN integer, psTEXT varchar2, pnROW_HEIGHT number := null, pbALLOW_HTML boolean := FALSE,
psDATA_TYPE varchar2 := 'String', psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null);
PROCEDURE APPEND_TEXT_WITH_STYLE_CLOB (psSTYLE varchar2, pbSTART_ROW boolean, pbEND_ROW boolean,
pnSTART_COLUMN integer, psTEXT CLOB, pnROW_HEIGHT number := null, pbALLOW_HTML boolean := FALSE,
psDATA_TYPE varchar2 := 'String', psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null);
PROCEDURE MERGE_CELLS(pnNUMBER_OF_ROWS integer, pnFIRST_COLUMN integer, pnNUMBER_OF_COLUMNS integer, pbCENTER_HORIZONTAL boolean := TRUE);
PROCEDURE INSERT_MERGE (pnCOLUMN integer);
PROCEDURE DECREMENT_MERGE_ROWS;
PROCEDURE INSERT_PAGE_BREAK;
FUNCTION GET_PAGE_BREAKS RETURN VARCHAR2;
FUNCTION HTMLEncode (psTEXT varchar2, bALLOW_HTML boolean := FALSE) RETURN varchar2;
FUNCTION HTMLEncode_CLOB (psTEXT varchar2, bALLOW_HTML boolean := FALSE) RETURN CLOB;
END;
/



create or replace PACKAGE BODY UTL_EXCEL AS
TYPE merge_type IS RECORD
(nCol     number,
nNumRows number,
nNumCols number,
bCenter  boolean);
TYPE merge_tbl_type IS TABLE OF merge_type
INDEX BY BINARY_INTEGER;
TYPE page_break_tbl_type IS TABLE OF integer
INDEX BY BINARY_INTEGER;
excel_data                clob;
current_row               integer;
current_column            integer;
merges                    merge_tbl_type;
merge_rows_left           integer;
merge_pending             boolean;
hidden_merge_split_factor number;
page_breaks               page_break_tbl_type;
PROCEDURE START_DOCUMENT (pnTAB_RATION integer:= null) AS
temp      varchar2(1000);
BEGIN
DBMS_LOB.CREATETEMPORARY(excel_data, true);
temp := '<?xml version="1.0"?>' || CHR(13) || CHR(10) ||
'<?mso-application progid="Excel.Sheet"?>' || CHR(13) || CHR(10) ||
'<Workbook' || CHR(13) || CHR(10) ||
'xmlns:x="urn:schemas-microsoft-com:office:excel"' || CHR(13) || CHR(10) ||
'xmlns="urn:schemas-microsoft-com:office:spreadsheet"' || CHR(13) || CHR(10) ||
'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' || CHR(13) || CHR(10) ||
'xmlns:h="http://www.w3.org/TR/REC-html40">' || CHR(13) || CHR(10);
IF pnTAB_RATION is not null THEN
temp := temp || '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">' || CHR(13) || CHR(10) ||
'<TabRatio>' || pnTAB_RATION || '</TabRatio>' || CHR(13) || CHR(10) ||
'</ExcelWorkbook>' || CHR(13) || CHR(10);
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE END_DOCUMENT AS
temp      varchar2(1000);
BEGIN
temp := '</Workbook>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
FUNCTION GET_CUR_COLUMN RETURN integer AS
BEGIN
RETURN current_column;
END;

FUNCTION GET_CUR_ROW RETURN integer AS
BEGIN
RETURN current_row;
END;

FUNCTION GET_DOCUMENT (pcKEEP_DATA char := 'N') RETURN clob AS
retval clob;
BEGIN
retval := excel_data;

IF pcKEEP_DATA = 'N' THEN
excel_data := null;
END IF;
RETURN retval;
END;
PROCEDURE START_WORKSHEET (psWORKSHEET_NAME varchar2, pbPROTECT boolean := FALSE) AS
temp      varchar2(1000);
BEGIN
temp := '<Worksheet ss:Name="' || psWORKSHEET_NAME || '"';
IF pbPROTECT THEN
temp := temp || ' ss:Protected="1"';
END IF;
temp := temp || '>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
current_row := 1;
current_column := 1;
page_breaks.DELETE;
END;

PROCEDURE END_WORKSHEET (pbADD_LEGAL_NOTE boolean := FALSE) AS
temp      varchar2(32000);
BEGIN
--Output Legal Notice
IF pbADD_LEGAL_NOTE THEN
-- remove the last page break if it falls just before this note
IF page_breaks.COUNT > 0 THEN
IF page_breaks(page_breaks.LAST) = current_row - 1 THEN
page_breaks.DELETE(page_breaks.LAST);
END IF;
END IF;
APPEND_TEXT('');
APPEND_TEXT_WITH_STYLE('LegalDistributionNoteBU', TRUE, TRUE, 1,
'FOR INTERNAL DISTRIBUTION ONLY: THIS REPORT MAY CONTAIN CONFIDENTIAL INFORMATION AND IS INTENDED ONLY FOR THE PERSON(S) NAMED.');
APPEND_TEXT_WITH_STYLE('LegalDistributionNote', TRUE, TRUE, 1,
'DISTRIBUTION TO ANYONE OUTSIDE THE ORGANIZATION IS STRICTLY PROHIBITED.ANY USE, COPYING OR DISCLOSURE BY ANOTHER PERSON IS STRICTLY PROHIBITED.');
APPEND_TEXT_WITH_STYLE('LegalDistributionNote', TRUE, TRUE, 1,
'IF YOU HAVE RECEIVED THIS REPORT IN ERROR, PLEASE NOTIFY THE SENDER AND RETURN THE DOCUMENT IMMEDIATELY.');
END IF;
temp := '</Table>' || CHR(13) || CHR(10);

temp := temp || GET_PAGE_BREAKS;
temp := temp || '</Worksheet>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE FORMAT_WORKSHEET (psORIENTATION varchar2 := 'Landscape', pbFIT_TO_PAGE boolean := TRUE,
pbSINGLE_PAGE boolean := FALSE, plPAPER_SIZE number := cXL_PAPER_LETTER, pbADD_HEADER boolean := TRUE,
pnFREEZE_PANE_ROW number := null) AS
temp      varchar2(1000);
BEGIN
IF psORIENTATION not in ('Landscape', 'Portrait') THEN
RAISE_APPLICATION_ERROR(-20104, 'Invalid Orientation');
END IF;
temp := '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">' || CHR(13) || CHR(10) ||
'<PageSetup>' || CHR(13) || CHR(10) ||
'<Layout' || CHR(13) || CHR(10) ||
'x:Orientation="' || psORIENTATION || '"' || CHR(13) || CHR(10) ||
'x:CenterHorizontal="1"/>' || CHR(13) || CHR(10);
temp := temp || '<PageMargins' || CHR(13) || CHR(10) ||
'x:Left="0.25"' || CHR(13) || CHR(10) ||
'x:Right="0.25"' || CHR(13) || CHR(10) ||
'x:Top="0.7"' || CHR(13) || CHR(10) ||
'x:Bottom="0.7"/>' || CHR(13) || CHR(10);
IF pbADD_HEADER THEN
temp := temp || '<Header x:Data="' || HTMLEncode('') || '" />' || CHR(13) || CHR(10);
END IF;
temp := temp || '<Footer x:Data="' || HTMLEncode('  of ') || '" />' || CHR(13) || CHR(10) ||
'</PageSetup>'  || CHR(13) || CHR(10);
IF pbFIT_TO_PAGE THEN
temp := temp || '<x:FitToPage/>' || CHR(13) || CHR(10);
END IF;
temp := temp || '<x:Print>' || CHR(13) || CHR(10);
IF pbFIT_TO_PAGE THEN
temp := temp || '<x:FitWidth>1</x:FitWidth><x:FitHeight>';
IF pbSINGLE_PAGE THEN
temp := temp || '1';
ELSE
temp := temp || '0';
END IF;
temp := temp || '</x:FitHeight>' || CHR(13) || CHR(10);
END IF;
temp := temp || '<x:ValidPrinterInfo/>' || CHR(13) || CHR(10) ||
'<x:PaperSizeIndex>' || plPAPER_SIZE || '</x:PaperSizeIndex>' || CHR(13) || CHR(10) ||
'</x:Print>' || CHR(13) || CHR(10);
IF pnFREEZE_PANE_ROW is not null THEN
temp := temp || '<FreezePanes/>' || CHR(13) || CHR(10) ||
'<FrozenNoSplit/>' || CHR(13) || CHR(10) ||
'<SplitHorizontal>' || TO_CHAR(pnFREEZE_PANE_ROW) || '</SplitHorizontal>' || CHR(13) || CHR(10) ||
'<TopRowBottomPane>' || TO_CHAR(pnFREEZE_PANE_ROW) || '</TopRowBottomPane>' || CHR(13) || CHR(10) ||
'<ActivePane>2</ActivePane>' || CHR(13) || CHR(10) ||
'<Panes>' || CHR(13) || CHR(10) ||
'<Pane>' || CHR(13) || CHR(10) ||
'<Number>3</Number>' || CHR(13) || CHR(10) ||
'</Pane>' || CHR(13) || CHR(10) ||
'<Pane>' || CHR(13) || CHR(10) ||
'<Number>2</Number>' || CHR(13) || CHR(10) ||
'</Pane>' || CHR(13) || CHR(10) ||
'</Panes>' || CHR(13) || CHR(10);
END IF;
temp := temp || '</WorksheetOptions>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE START_NAMES AS
temp      varchar2(1000);
BEGIN
temp := '<ss:Names>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE FINISH_NAMES AS
temp      varchar2(1000);
BEGIN
temp := '</ss:Names>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE CREATE_NAME (psNAME varchar2, psRANGE varchar2 := null) AS
temp      varchar2(1000);
BEGIN
temp := '<NamedRange ss:Name="' || psNAME || '"';
IF psRANGE is not null THEN
temp := temp || ' ss:RefersTo="' || psRANGE || '"';
END IF;
temp := temp || '/>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE CREATE_AUTOFILTER(pnSTART_ROW integer, pnEND_ROW integer, pnNUM_COLUMNS integer) AS
temp      varchar2(1000);
BEGIN
temp := '<AutoFilter x:Range="R' || pnSTART_ROW || 'C1:R' || pnEND_ROW ||  'C' || pnNUM_COLUMNS || '" xmlns="urn:schemas-microsoft-com:office:excel"/>';
temp := temp || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE START_STYLES AS
temp      varchar2(1000);
BEGIN
temp := '<Styles>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
-- Always create styles for the Legal Distribution text
CREATE_STYLE ('LegalDistributionNote', 'Left', False, pnFONT_SIZE => 7);
CREATE_STYLE ('LegalDistributionNoteBU', 'Left', False, pnFONT_SIZE => 7, pbBOLD=> TRUE, pbUNDERLINE => TRUE);
END;
PROCEDURE FINISH_STYLES AS
temp      varchar2(1000);
BEGIN
temp := '</Styles>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE CREATE_STYLE (psSTYLE varchar2, psHORIZ_ALIGN varchar2, pbWRAP_TEXT boolean,
pnROTATION integer := 0, pbBORDERS boolean := FALSE, pnFONT_SIZE integer := 10,
pbBOLD boolean := FALSE, pbUNDERLINE boolean := FALSE, pbITALIC boolean := FALSE,
psNUMBER_FORMAT varchar2 := null, psFORE_COLOR_CODE varchar2 := null, psBACK_COLOR_CODE varchar2 := null) AS
temp      varchar2(1000);
BEGIN
temp := '<Style ss:ID="' || psSTYLE || '">' || CHR(13) || CHR(10);
temp := temp || '<Alignment' ||
' ss:Horizontal="' || psHORIZ_ALIGN || '"' ||
' ss:Vertical="Center"';
IF pbWRAP_TEXT THEN
temp := temp || ' ss:WrapText="1"';
END IF;
IF pnROTATION <> 0 THEN
temp := temp || ' ss:Rotate="' || pnROTATION || '"';
END IF;
temp := temp || '/>' || CHR(13) || CHR(10);
IF pbBORDERS THEN
temp := temp || '<Borders>' || CHR(13) || CHR(10);
temp := temp || '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>' || CHR(13) || CHR(10);
temp := temp || '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' || CHR(13) || CHR(10);
temp := temp || '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' || CHR(13) || CHR(10);
temp := temp || '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' || CHR(13) || CHR(10);
temp := temp || '</Borders>' || CHR(13) || CHR(10);
END IF;
temp := temp || '<Font ss:Size="' || pnFONT_SIZE || '"';
IF pbBOLD THEN
temp := temp || ' ss:Bold="1"';
END IF;
IF pbUNDERLINE THEN
temp := temp || ' ss:Underline="Single"';
END IF;
IF pbITALIC THEN
temp := temp || ' ss:Italic="1"';
END IF;
IF psFORE_COLOR_CODE is not null THEN
temp := temp || ' ss:Color="' || psFORE_COLOR_CODE || '"';
END IF;
temp := temp || '/>' || CHR(13) || CHR(10);
IF psNUMBER_FORMAT is not null THEN
temp := temp || '<NumberFormat ss:Format="' || psNUMBER_FORMAT || '"/>' || CHR(13) || CHR(10);
END IF;
IF psBACK_COLOR_CODE is not null THEN
temp := temp || '<Interior ss:Color="' || psBACK_COLOR_CODE || '" ss:Pattern="Solid"/>' || CHR(13) || CHR(10);
END IF;
temp := temp || '</Style>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE CREATE_STYLE (psSTYLE varchar2, psHORIZ_ALIGN varchar2, pbWRAP_TEXT boolean,
poBORDERS border_array, pnROTATION integer := 0, pnFONT_SIZE integer := 10,
pbBOLD boolean := FALSE, pbUNDERLINE boolean := FALSE, pbITALIC boolean := FALSE,
psNUMBER_FORMAT varchar2 := null, psFORE_COLOR_CODE varchar2 := null, psBACK_COLOR_CODE varchar2 := null) AS
temp      varchar2(1000);
BEGIN
temp := '<Style ss:ID="' || psSTYLE || '">' || CHR(13) || CHR(10);
temp := temp || '<Alignment' ||
' ss:Horizontal="' || psHORIZ_ALIGN || '"' ||
' ss:Vertical="Center"';
IF pbWRAP_TEXT THEN
temp := temp || ' ss:WrapText="1"';
END IF;
IF pnROTATION <> 0 THEN
temp := temp || ' ss:Rotate="' || pnROTATION || '"';
END IF;
temp := temp || '/>' || CHR(13) || CHR(10);
temp := temp || '<Borders>' || CHR(13) || CHR(10);
FOR i in poBORDERS.FIRST() .. poBORDERS.LAST() LOOP
temp := temp || '<Border ss:Position="' || poBORDERS(i).sPosition || '" ss:LineStyle="' || poBORDERS(i).sLineStyle ||
'" ss:Weight="' || poBORDERS(i).nWeight || '"/>' || CHR(13) || CHR(10);
END LOOP;
temp := temp || '</Borders>' || CHR(13) || CHR(10);
temp := temp || '<Font ss:Size="' || pnFONT_SIZE || '"';
IF pbBOLD THEN
temp := temp || ' ss:Bold="1"';
END IF;
IF pbUNDERLINE THEN
temp := temp || ' ss:Underline="Single"';
END IF;
IF pbITALIC THEN
temp := temp || ' ss:Italic="1"';
END IF;
IF psFORE_COLOR_CODE is not null THEN
temp := temp || ' ss:Color="' || psFORE_COLOR_CODE || '"';
END IF;
temp := temp || '/>' || CHR(13) || CHR(10);
IF psNUMBER_FORMAT is not null THEN
temp := temp || '<NumberFormat ss:Format="' || psNUMBER_FORMAT || '"/>' || CHR(13) || CHR(10);
END IF;
IF psBACK_COLOR_CODE is not null THEN
temp := temp || '<Interior ss:Color="' || psBACK_COLOR_CODE || '" ss:Pattern="Solid"/>' || CHR(13) || CHR(10);
END IF;
temp := temp || '</Style>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE START_TABLE AS --(pnCOLUMNS integer, pnMIN_COLUMNS integer := 0) AS
temp      varchar2(1000);
BEGIN
temp := '<Table>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE DEFINE_COLUMN (pnCOLUMN integer, pnWIDTH number) AS
temp      varchar2(1000);
BEGIN
temp := '<Column ss:Index="' || pnCOLUMN ||'" ss:Width="' || LTRIM(TO_CHAR(pnWIDTH * 5.6, '999.99')) || '"/>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE APPEND_TEXT (psTEXT varchar2, pnROW_HEIGHT number := null, psDATA_TYPE varchar2 := 'String',
psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null) AS
temp      varchar2(4000);
BEGIN
temp := '<Row';
IF pnROW_HEIGHT is not null THEN
temp := temp || ' ss:Height="' || pnROW_HEIGHT || '"';
END IF;
temp := temp || '>' || CHR(13) || CHR(10);
temp := temp || '<Cell ss:StyleID="text"';
IF psFORMULA is not null THEN
temp := temp || ' ss:Formula="' || psFORMULA || '"';
END IF;
IF psLINK is not null THEN
temp := temp || ' ss:HRef="' || psLINK || '"';
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
IF merge_pending THEN
INSERT_MERGE(current_column);
END IF;
temp := '>';
temp := temp || '<Data ss:Type="' || psDATA_TYPE || '">' || HTMLEncode(psTEXT) || '</Data>';
IF psNAME is not null THEN
temp := temp || '<NamedCell ss:Name="' || psNAME || '"/>';
END IF;
temp := temp || '</Cell>' || CHR(13) || CHR(10);
temp := temp || '</Row>' || CHR(13) || CHR(10);
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
DECREMENT_MERGE_ROWS;
current_row := current_row + 1;
current_column := 1;
END;
PROCEDURE APPEND_TEXT_WITH_STYLE (psSTYLE varchar2, pbSTART_ROW boolean, pbEND_ROW boolean,
pnSTART_COLUMN integer, psTEXT varchar2, pnROW_HEIGHT number := null, pbALLOW_HTML boolean := FALSE,
psDATA_TYPE varchar2 := 'String', psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null) AS
temp      varchar2(4000);
BEGIN
IF pbSTART_ROW THEN
temp := '<Row';
IF pnROW_HEIGHT is not null THEN
temp := temp || ' ss:Height="' || pnROW_HEIGHT || '"';
END IF;
temp := temp || '>' || CHR(13) || CHR(10);
END IF;
temp := temp || '<Cell';
IF pnSTART_COLUMN <> current_column THEN
temp := temp || ' ss:Index="' || pnSTART_COLUMN || '"';
current_column := pnSTART_COLUMN;
END IF;
temp := temp || ' ss:StyleID="' || psSTYLE || '"';
IF psFORMULA is not null THEN
temp := temp || ' ss:Formula="' || psFORMULA || '"';
END IF;
IF psLINK is not null THEN
temp := temp || ' ss:HRef="' || psLINK || '"';
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
IF merge_pending THEN
INSERT_MERGE(current_column);
END IF;
temp := '>';
temp := temp || '<Data ss:Type="' || psDATA_TYPE || '">' || HTMLEncode(psTEXT, pbALLOW_HTML) || '</Data>';
IF psNAME is not null THEN
temp := temp || '<NamedCell ss:Name="' || psNAME || '"/>';
END IF;
temp := temp || '</Cell>' || CHR(13) || CHR(10);
current_column := current_column + 1;
IF pbEND_ROW THEN
temp := temp || '</Row>' || CHR(13) || CHR(10);
DECREMENT_MERGE_ROWS;
current_column := 1;
current_row := current_row + 1;
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE APPEND_TEXT_WITH_STYLE_CLOB (psSTYLE varchar2, pbSTART_ROW boolean, pbEND_ROW boolean,
pnSTART_COLUMN integer, psTEXT CLOB, pnROW_HEIGHT number := null, pbALLOW_HTML boolean := FALSE,
psDATA_TYPE varchar2 := 'String', psFORMULA varchar2 := null, psLINK varchar2 := null, psNAME varchar2 := null) AS
temp      CLOB;
BEGIN
IF pbSTART_ROW THEN
temp := '<Row';
IF pnROW_HEIGHT is not null THEN
temp := temp || ' ss:Height="' || pnROW_HEIGHT || '"';
END IF;
temp := temp || '>' || CHR(13) || CHR(10);
END IF;
temp := temp || '<Cell';
IF pnSTART_COLUMN <> current_column THEN
temp := temp || ' ss:Index="' || pnSTART_COLUMN || '"';
current_column := pnSTART_COLUMN;
END IF;
temp := temp || ' ss:StyleID="' || psSTYLE || '"';
IF psFORMULA is not null THEN
temp := temp || ' ss:Formula="' || psFORMULA || '"';
END IF;
IF psLINK is not null THEN
temp := temp || ' ss:HRef="' || psLINK || '"';
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
IF merge_pending THEN
INSERT_MERGE(current_column);
END IF;
temp := '>';
temp := temp || '<Data ss:Type="' || psDATA_TYPE || '">' || HTMLEncode(psTEXT, pbALLOW_HTML) || '</Data>';
IF psNAME is not null THEN
temp := temp || '<NamedCell ss:Name="' || psNAME || '"/>';
END IF;
temp := temp || '</Cell>' || CHR(13) || CHR(10);
current_column := current_column + 1;
IF pbEND_ROW THEN
temp := temp || '</Row>' || CHR(13) || CHR(10);
DECREMENT_MERGE_ROWS;
current_column := 1;
current_row := current_row + 1;
END IF;
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END;
PROCEDURE MERGE_CELLS(pnNUMBER_OF_ROWS integer, pnFIRST_COLUMN integer, pnNUMBER_OF_COLUMNS integer, pbCENTER_HORIZONTAL boolean := TRUE) AS
new_index integer := NVL(merges.LAST(), 0) + 1;
BEGIN
merges(new_index).nCol := pnFIRST_COLUMN;
merges(new_index).nNumRows := pnNUMBER_OF_ROWS;
merges(new_index).nNumCols := pnNUMBER_OF_COLUMNS;
merges(new_index).bCenter := pbCENTER_HORIZONTAL;
merge_pending := TRUE;
merge_rows_left := pnNUMBER_OF_ROWS; --must be consistent across row !!!
END;
PROCEDURE INSERT_MERGE (pnCOLUMN integer) AS
temp      varchar2(1000);
BEGIN
FOR i in 1 .. NVL(merges.LAST(), 0) LOOP
IF merges(i).nCol = pnCOLUMN THEN
IF merges(i).nNumCols <> 1 THEN
temp := temp || ' ss:MergeAcross="' || (merges(i).nNumCols - 1) || '"';
END IF;
IF merges(i).nNumRows <> 1 THEN
temp := temp || ' ss:MergeDown="' || (merges(i).nNumRows - 1) || '"';
hidden_merge_split_factor := merges(i).nNumRows;
END IF;
EXIT;
END IF;
END LOOP;
IF temp is not null THEN
DBMS_LOB.WRITEAPPEND(excel_data, LENGTH(temp), temp);
END IF;
END;
PROCEDURE DECREMENT_MERGE_ROWS AS
BEGIN
merge_pending := FALSE;
IF merge_rows_left <> 0 THEN
merge_rows_left := merge_rows_left - 1;
END IF;
IF merge_rows_left = 0 THEN
merges.DELETE;
END IF;
END;

PROCEDURE INSERT_PAGE_BREAK AS
BEGIN
page_breaks(NVL(page_breaks.LAST, 0) + 1) := current_row - 1;
END;

FUNCTION GET_PAGE_BREAKS RETURN VARCHAR2 AS
temp      varchar2(32000);
BEGIN
IF page_breaks.COUNT > 0 THEN
temp := '<PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">' || CHR(13) || CHR(10);
temp := temp || '<RowBreaks>' || CHR(13) || CHR(10);
FOR i IN page_breaks.FIRST .. page_breaks.LAST LOOP
temp := temp || '<RowBreak><Row>' || page_breaks(i) ||'</Row></RowBreak>' || CHR(13) || CHR(10);
END LOOP;
temp := temp || '</RowBreaks>' || CHR(13) || CHR(10);
temp := temp || '</PageBreaks>' || CHR(13) || CHR(10);
END IF;
RETURN temp;
END;
FUNCTION HTMLEncode (psTEXT varchar2, bALLOW_HTML boolean := FALSE) RETURN varchar2 AS
result varchar2(32000);
repl   varchar2(15);
acode  integer;
BEGIN

result := REPLACE(psTEXT, CHR(13) || CHR(10), CHR(10));
IF psTEXT is not null THEN
FOR i IN REVERSE 1 .. LENGTH(result) LOOP
acode := ASCII(SUBSTR(result, i, 1));
IF acode = 34 THEN
repl := ';';

ELSIF acode = 38 THEN
IF bALLOW_HTML THEN
repl := '&';
ELSE
repl := ';';
END IF;
ELSIF acode = 60 THEN
IF bALLOW_HTML THEN
repl := '<';
ELSE
repl := ';';
END IF;
ELSIF acode = 62 THEN
IF bALLOW_HTML THEN
repl := '>';
ELSE
repl := ';';
END IF;
ELSIF acode between 32 and 127 THEN
-- don't touch alphanumeric chars
null;
ELSE
repl := '&#' || TO_CHAR(acode) || ';';
END IF;
IF LENGTH(repl) > 0 THEN
result := SUBSTR(result, 1, i - 1) || repl || SUBSTR(result, i + 1);
repl := '';
END IF;
END LOOP;
END IF;
RETURN result;
END;
FUNCTION HTMLEncode_CLOB (psTEXT varchar2, bALLOW_HTML boolean := FALSE) RETURN CLOB AS
result varchar2(32000);
repl   varchar2(10);
acode  integer;
BEGIN
-- 07/18/07 - SHC - Eliminate box characters in comments
result := REPLACE(psTEXT, CHR(13) || CHR(10), CHR(10));
IF psTEXT is not null THEN
FOR i IN REVERSE 1 .. LENGTH(result) LOOP
acode := ASCII(SUBSTR(result, i, 1));
IF acode = 34 THEN
repl := ';';
--            Case 32
--               repl = ";"
ELSIF acode = 38 THEN
IF bALLOW_HTML THEN
repl := '&';
ELSE
repl := ';';
END IF;
ELSIF acode = 60 THEN
IF bALLOW_HTML THEN
repl := '<';
ELSE
repl := ';';
END IF;
ELSIF acode = 62 THEN
IF bALLOW_HTML THEN
repl := '>';
ELSE
repl := ';';
END IF;
ELSIF acode between 32 and 127 THEN

null;
ELSE
repl := '&#' || TO_CHAR(acode) || ';';
END IF;
IF LENGTH(repl) > 0 THEN
result := SUBSTR(result, 1, i - 1) || repl || SUBSTR(result, i + 1);
repl := '';
END IF;
END LOOP;
END IF;
RETURN result;
END;
END;
/