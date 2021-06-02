create or replace PROCEDURE GRANT_VIEW_PREV_GENERIC (schemaName VARCHAR2)
AS
BEGIN

    FOR R IN (SELECT owner, view_name
                FROM all_views
               WHERE owner = UPPER (schemaName))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT SELECT  ON '
                             || R.owner
                             || '.'
                             || R.view_name
                             || ' to '
                             || R.owner
                             || '_SELECT';

           /* DBMS_OUTPUT.put_line (
                   'GRANT SELECT  ON '
                || R.owner
                || '.'
                || R.view_name
                || ' to '
                || R.owner
                || '_SELECT_ALL');*/
        EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.view_name ||' : '|| SQLERRM);
End;
    END LOOP;
dbms_output.put_line('First loop completed!');


    FOR R IN (SELECT owner, view_name
                FROM all_views
               WHERE owner = UPPER (schemaName))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT SELECT,INSERT,UPDATE,DELETE  ON '
                             || R.owner
                             || '.'
                             || R.view_name
                             || ' to '
                             || R.owner
                             || '_SUPPORT';

          /*  DBMS_OUTPUT.put_line (
                   'GRANT SELECT,INSERT,UPDATE,DELETE  ON '
                || R.owner
                || '.'
                || R.view_name
                || ' to '
                || R.owner
                || '_SUPPORT_ALL');*/
           EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.view_name ||' : '|| SQLERRM);
End;
    END LOOP;

dbms_output.put_line('Second loop completed!');

    FOR R IN (SELECT owner, view_name
                FROM all_views
               WHERE owner = UPPER (schemaName))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'GRANT ALL PRIVILEGES ON '
                             || R.owner
                             || '.'
                             || R.view_name
                             || ' to '
                             || R.owner
                             || '_ADMIN';

            /*DBMS_OUTPUT.put_line (
                   'GRANT ALL PRIVILEGES  ON '
                || R.owner
                || '.'
                || R.view_name
                || ' to '
                || R.owner
                || '_ADMIN_ALL');*/
           EXCEPTION
    WHEN OTHERS
    THEN
       dbms_output.put_line('Error in ' || R.owner || '.' || R.view_name ||' : '|| SQLERRM);
End;
    END LOOP;
dbms_output.put_line('Third loop completed!');

EXCEPTION
    WHEN OTHERS
    THEN
        raise_application_error (-20100,
                                 'error#' || SQLCODE || ' desc: ' || SQLERRM);
        RETURN;

END;
/