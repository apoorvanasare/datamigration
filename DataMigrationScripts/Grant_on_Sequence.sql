create or replace PROCEDURE GRANT_SEQ_PREV_GENERIC (schemaName VARCHAR2)
AS
BEGIN


    FOR R IN (SELECT sequence_owner, sequence_name
                FROM all_sequences
               WHERE sequence_owner = schemaName)
    LOOP
    BEGIN
    dbms_output.put_line( R.sequence_owner || '.' || R.sequence_name);
        EXECUTE IMMEDIATE   'GRANT SELECT  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_SELECT'
                         ;

       /* DBMS_OUTPUT.put_line (
               'GRANT SELECT  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_SELECT_ALL ');*/

			EXECUTE IMMEDIATE   'GRANT SELECT,ALTER  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_SUPPORT'
                         ;

       /* DBMS_OUTPUT.put_line (
               'GRANT SELECT  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_SUPPORT_ALL');*/

			EXECUTE IMMEDIATE   'GRANT ALL PRIVILEGES  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_ADMIN';

     /*   DBMS_OUTPUT.put_line (
               'GRANT ALL PRIVILEGES  ON '
                         || R.sequence_owner
                         || '.'
                         || R.sequence_name
                         || ' to '
                         || R.sequence_owner
                         || '_ADMIN_ALL');*/

EXCEPTION
    WHEN OTHERS
    THEN

       dbms_output.put_line('Error in ' || R.sequence_owner || '.' || R.sequence_name ||' : '|| SQLERRM);
End;
END LOOP;
    dbms_output.put_line('First Loop Completed');

EXCEPTION
    WHEN OTHERS
    THEN
        raise_application_error (-20100,
                                 'error#' || SQLCODE || ' desc: ' || SQLERRM);
        RETURN;
END;
/