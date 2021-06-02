
create or replace PROCEDURE HYBRID_PRE_POST_DV_REPORT (
    ipAzureSchema   IN VARCHAR2 DEFAULT '%',
    ipAzureTable    IN VARCHAR2 DEFAULT '%',
    ipLegacyTable   IN VARCHAR2 DEFAULT '%',
    ipTargetTable   IN NUMBER)
AS
BEGIN
    DECLARE
        sSql                VARCHAR2 (32000);
        sSql1               VARCHAR2 (32000);
        sSql2               VARCHAR2 (32000);
        sSql3               VARCHAR2 (32000);
        sSql4               VARCHAR2 (32000);
        sSql5               VARCHAR2 (32000);
        sSql6               VARCHAR2 (32000);
        sSql7               VARCHAR2 (32000);
        sSql8               VARCHAR2 (32000);
        sSql9               VARCHAR2 (32000);
        pkValueSQL          VARCHAR2 (32000) := '';
        pkColumnSQL         VARCHAR2 (32000) := '';
        sErr                VARCHAR2 (1) := 'N';
        dbLink_name          VARCHAR2 (30) := '@DBlink_name';
        v_col_diff_select   VARCHAR2 (32000);
        v_col_diff_sql      VARCHAR2 (32000);
        val_table_1         VARCHAR2 (50):='VALIDATION_REPORT_COL_WISE_1';
        val_table_2         VARCHAR2(50):='VALIDATION_REPORT_COL_WISE_2';
        val_table           VARCHAR2(50):='';

        CURSOR c0 IS
              SELECT DISTINCT m.Legacy_Schema,
                              m.Legacy_Table, 
                              m.Azure_Schema,
                              m.Azure_Table,  
                             MAX (m.pk_position)     total_pk_columns
                FROM MAPPING_PK_CONFIG m
               WHERE     m.pk_column = 'Y'
                     AND m.diff_req = 'Y'
                     AND UPPER (m.Legacy_Table) LIKE
                             UPPER (TRIM (ipLegacyTable)) || '%'
                     AND UPPER (m.Azure_Schema) LIKE
                             UPPER (TRIM (ipAzureSchema)) || '%'
                     AND UPPER (m.Azure_Table) LIKE
                             UPPER (TRIM (ipAzureTable)) || '%'
            GROUP BY m.Legacy_Schema,
                     m.Legacy_Table, 
                     m.Azure_Schema,
                     m.Azure_Table
            ORDER BY m.Legacy_Schema, m.Legacy_Table, m.Azure_Table;

        CURSOR c1 (ip_legacy_schema   IN VARCHAR2,
                   ip_legacy_table    IN VARCHAR2,
                   ip_azure_schema    IN VARCHAR2,
                   ip_azure_table     IN VARCHAR2)
        IS
              SELECT m.id,
                     m.Legacy_Schema,
                     m.Legacy_Table,
                     m.LegacyColumn,
                     m.Azure_Schema,
                     m.Azure_Table,
                     m.AzureColumn,
                     m.pk_column,
                     m.pk_position,
                     m.pk_operator,
                     m.pk_criteria
                FROM MAPPING_PK_CONFIG m
               WHERE     UPPER (m.Legacy_Schema) = UPPER (ip_legacy_schema)
                     AND UPPER (m.Legacy_Table) = UPPER (ip_legacy_table)
                     AND UPPER (m.Azure_Schema) = UPPER (ip_azure_schema)
                     AND UPPER (m.Azure_Table) = UPPER (ip_azure_table)
                     AND M.Pk_Column = 'Y'
                     AND m.diff_req = 'Y'
            ORDER BY m.Legacy_Schema,
                     m.Legacy_Table,
                     m.Azure_Table,
                     DECODE (m.pk_column, 'Y', 1, 2),
                     m.pk_position,
                     m.LegacyColumn;

        CURSOR c2 (ip_legacy_schema   IN VARCHAR2,
                   ip_legacy_table    IN VARCHAR2,
                   ip_azure_table     IN VARCHAR2)
        IS
              SELECT m.id,
                     m.Legacy_Schema,
                     m.Legacy_Table,
                     m.LegacyColumn,
                     m.data_type             legacy_type,
                     m.Azure_Schema,
                     m.Azure_Table,
                     m.AzureColumn,
                     m.AZURE_DATA_TYPE     azure_type,
                     m.pk_column,
                     m.pk_operator,
                     m.pk_criteria
                FROM MAPPING_PK_CONFIG m
               WHERE     UPPER (Legacy_Schema) = UPPER (ip_legacy_schema)
                     AND UPPER (Legacy_Table) = UPPER (ip_legacy_table)
                     AND LegacyColumn <> '#'
                     AND UPPER (m.Azure_Table) = UPPER (ip_azure_table)
                    AND NVL (m.pk_column, 'X') <>'Y'
                     AND m.diff_req = 'Y'
            ORDER BY m.Legacy_Schema,
                     m.Legacy_Table,
                     m.Azure_Table,
                     DECODE (m.pk_column, 'Y', 1, 2),
                     m.LegacyColumn;

        nCnt                NUMBER := 0;
    BEGIN

        IF(iptargettable=2) then
            val_table := val_table_1;
        else
            val_table := val_table_2;
        end if;

        FOR Rec IN c0
        LOOP
            sSql :=
                   'select count(*)
              from '
                || rec.Azure_Schema
                || '.'
                || rec.Azure_Table
                || ' t'
                || '
             where exists (select 1
                             from '
                || rec.Legacy_Schema
                || '.'
                || rec.Legacy_Table
                || dbLink_name                   
                || ' s'
                || ' 
                            where ';           

            sSql2 :=
                   ' from '
                || rec.Azure_Schema
                || '.'
                || rec.Azure_Table
                || ' t,'
                || rec.Legacy_Schema
                || '.'
                || rec.Legacy_Table
                || dbLink_name
                || ' s'
                || ' 
                            where ';

            -- where with PK condition
            FOR recPK IN c1 (rec.Legacy_Schema,
                             rec.Legacy_Table,
                             rec.Azure_Schema,
                             rec.Azure_Table)
            LOOP
                IF (   (rec.total_pk_columns = 1)
                    OR (rec.total_pk_columns <> recPK.pk_position))
                THEN
                    IF (recPK.pk_operator = '=')
                    THEN
                        IF (recPK.pk_position = 1)
                        THEN
                            sSql :=
                                   sSql
                                || 's.'
                                || recPK.LegacyColumn
                                || ' = '
                                || 't.'
                                || recPK.AzureColumn;
                            sSql2 :=
                                   sSql2
                                || 's.'
                                || recPK.LegacyColumn
                                || ' = '
                                || 't.'
                                || recPK.AzureColumn;
                            sSql7 :=
                                   sSql7
                                || 'a1.'
                                || recPK.AzureColumn
                                || ' = '
                                || 'b1.'
                                || recPK.AzureColumn;
                            sSql8 := sSql8 || 't.' || recPK.AzureColumn;
                            pkValueSQL := 't.' || recPK.AzureColumn;
                        ELSE
                            sSql :=
                                   sSql
                                || ' and s.'
                                || recPK.LegacyColumn
                                || ' = '
                                || 't.'
                                || recPK.AzureColumn;
                            sSql2 :=
                                   sSql2
                                || ' and s.'
                                || recPK.LegacyColumn
                                || ' = '
                                || 't.'
                                || recPK.AzureColumn;

                            sSql7 :=
                                   sSql7
                                || ' and a1.'
                                || recPK.AzureColumn
                                || ' = '
                                || 'b1.'
                                || recPK.AzureColumn;

                            sSql8 := sSql8 || ' , t.' || recPK.AzureColumn;
                            pkValueSQL :=
                                   pkValueSQL
                                || '||'
                                || '''||'''
                                || '||t.'
                                || recPK.AzureColumn;
                        END IF;
                    ELSE
                        IF (recPK.pk_position = 1)
                        THEN
                            sSql := sSql || recPK.pk_criteria;
                            sSql2 := sSql2 || recPK.pk_criteria;
                            pkValueSQL := 't.' || recPK.AzureColumn;
                            sSql7 :=
                                   sSql7
                                || 'a1.'
                                || recPK.AzureColumn
                                || ' = '
                                || 'b1.'
                                || recPK.AzureColumn;
                            sSql8 := sSql8 || ' t.' || recPK.AzureColumn;
                        ELSE
                            sSql := sSql || ' and ' || recPK.pk_criteria;
                            sSql2 := sSql2 || ' and ' || recPK.pk_criteria;
                            sSql7 :=
                                   sSql7
                                || ' a1.'
                                || recPK.AzureColumn
                                || ' = '
                                || 'b1.'
                                || recPK.AzureColumn;
                            sSql8 := sSql8 || ' t.' || recPK.AzureColumn;
                            pkValueSQL :=
                                   pkValueSQL
                                || '||'
                                || '''||'''
                                || '||t.'
                                || recPK.AzureColumn;
                        END IF;
                    END IF;
                ELSE
                    IF (recPK.pk_operator = '=')
                    THEN
                        sSql :=
                               sSql
                            || ' and s.'
                            || recPK.LegacyColumn
                            || ' = '
                            || 't.'
                            || recPK.AzureColumn;
                        sSql7 :=
                               sSql7
                            || ' and a1.'
                            || recPK.AzureColumn
                            || ' = '
                            || 'b1.'
                            || recPK.AzureColumn;
                        sSql8 := sSql8 || ' , t.' || recPK.AzureColumn;
                        sSql2 :=
                               sSql2
                            || ' and s.'
                            || recPK.LegacyColumn
                            || ' = '
                            || 't.'
                            || recPK.AzureColumn;
                        pkValueSQL :=
                               pkValueSQL
                            || '||'
                            || '''||'''
                            || '|| s.'
                            || recPK.LegacyColumn;
                    ELSE
                        sSql := sSql || ' and ' || recPK.pk_criteria;
                        sSql2 := sSql2 || ' and ' || recPK.pk_criteria;
                        pkValueSQL :=
                               pkValueSQL
                            || '||'
                            || '''||'''
                            || '|| t.'
                            || recPK.AzureColumn;
                        sSql7 :=
                               sSql7
                            || 'a1.'
                            || recPK.AzureColumn
                            || ' = '
                            || 'b1.'
                            || recPK.AzureColumn;
                        sSql8 := sSql8 || ' t.' || recPK.AzureColumn;
                    END IF;
                END IF;
            END LOOP;


            FOR kolumn
                IN c2 (rec.Legacy_Schema,
                       rec.Legacy_Table,
                       rec.Azure_Table)
            LOOP

                sSql1 :=
                       sSql
                    || ' and '
                    || get_column_format_post_rpt (kolumn.LegacyColumn,
                                                   kolumn.legacy_type,
                                                   's')
                    || ' <> '
                    || get_column_format_post_rpt (kolumn.AzureColumn,
                                                   kolumn.azure_type,
                                                   't')
                    || ')';

                sSql3 :=
                       sSql2
                    || ' and '
                    || get_column_format_post_rpt (kolumn.LegacyColumn,
                                                   kolumn.legacy_type,
                                                   's')
                    || ' <> '
                    || get_column_format_post_rpt (kolumn.AzureColumn,
                                                   kolumn.azure_type,
                                                   't');
                nCnt := 0;


                BEGIN
                    sErr := 'N';
                    EXECUTE IMMEDIATE sSql1
                    INTO nCnt;

                    Ssql5 :=
                           'INSERT INTO '|| val_table ||' (ID,LEGACY_SCHEMA,
                LEGACY_TABLE,LEGACY_COLUMN, AZURE_SCHEMA,AZURE_TABLE,AZURE_COLUMN,
                CURRENT_LEGACY_VALUE,PRE_AZURE_VALUE,TARGET_ROWID,PK_VALUE,POST_AZURE_VALUE) WITH data AS ( select '
                        || ''''
                        || kolumn.id
                        || ''' as id,'''
                        || rec.Legacy_Schema
                        || ''' as Legacy_Schema,'''
                        || rec.Legacy_Table
                        || ''' as Legacy_Table,'''
                        || kolumn.LegacyColumn
                        || ''' as Legacy_Column,'''
                        || rec.Azure_Schema
                        || ''' as Azure_Schema,'''
                        || rec.Azure_Table
                        || ''
                        || ''' as Azure_Table,'''
                        || kolumn.AzureColumn
                        || ''' as Azure_Column'
                        || ',s.'
                        || kolumn.LegacyColumn
                        || ' as Azure_Column_lgcy'
                        || ',t.'
                        || kolumn.AzureColumn
                        || ' as Azure_Column_azr'
                        || ',t.ROWID as rowid1,'
                        || pkValueSQL
                        || ' as pkValueSQL'
                        || ','
                        || sSql8
                        || sSql3
                        || ') SELECT a1.id,a1.Legacy_Schema,a1.Legacy_Table,a1.Legacy_Column,a1.Azure_Schema,a1.Azure_Table,a1.AZURE_COLUMN,a1.Azure_Column_lgcy,a1.Azure_Column_azr,a1.rowid1,a1.pkValueSQL,b1.'
                        || kolumn.AzureColumn
                        || ' FROM data a1,'
                        || rec.Azure_Schema
                        || '.'
                        || rec.Azure_Table
                        || ' b1 WHERE '
                        || sSql7;

                    
                    DBMS_OUTPUT.put_line ('sSql5 -' || Ssql5);

                    IF (nCnt > 0)
                    THEN
                          Execute Immediate Ssql5;
                        COMMIT;
                    END IF;

                dbms_output.put_line('Ssql1 : '||Ssql1);
                 dbms_output.put_line('Ssql5 : '||Ssql5);

                EXCEPTION
                    WHEN OTHERS
                    THEN
                        sErr := 'Y';
                        DBMS_OUTPUT.put_line ('Error -' || SQLERRM);
                END;



                COMMIT;
                DBMS_OUTPUT.put_line (
                       'Diff -'
                    || nCnt
                    || ' - Updated: '
                    || SQL%ROWCOUNT
                    || ' - ID: '
                    || TO_NUMBER (kolumn.id));
            END LOOP;                                               -- columns



            COMMIT;
        END LOOP;                                                        -- pk
    END;
END HYBRID_PRE_POST_DV_REPORT;
/


