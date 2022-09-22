# Query validation checklist
## OLTP And OLAP
1. Check the consistency of the data type inside the WHERE clause between the fields in the tables and the variables, especially VARCHAR, NVARCHAR, CHAR and NCHAR.

2. In case of queries with multiple joins, try to divide the queries in sub-queries (CTE are considered additional joins).

3. Set the **ANSI_NULL** and **QUOTED_IDENTIFIER** to **ON**.

4. In case of queries with multiple OR conditions inside the WHERE clause related to different tables, split the queries using UNION and removing the OR condition (https://blogs.msdn.microsoft.com/sqlcat/2013/09/09/when-to-break-down-complex-queries/ case 1), see the following example:

```sql
SELECT Count(codicematricola)
FROM   fashion..matricole
WHERE  ( ( stato IN ( 80, 90 )
           AND mag1_id IN (SELECT id_magazzinifisici
                           FROM   fashion..magazzinifisici
                           WHERE  abilitatoanagrafica = 1) )
          OR ( stato = 120
               AND mag1_id = 264 )-- vedere commento del 04/08/2006
        )
       AND scaricata = 0
       AND annullatalogicamente = 0
       AND articolo_id = @Articolo_ID
       AND mag2_id = mag1_id 
``` 
Needs to be converted in:
```sql
SELECT Sum(t.num)
FROM   (SELECT Count(codicematricola) AS num
        FROM   fashion..matricole
        WHERE  (( stato IN ( 80, 90 )
                  AND mag1_id IN (SELECT id_magazzinifisici
                                  FROM   fashion..magazzinifisici
                                  WHERE  abilitatoanagrafica = 1) ))
               AND scaricata = 0
               AND annullatalogicamente = 0
               AND articolo_id = @Articolo_ID
               AND mag2_id = mag1_id
        UNION ALL
        SELECT Count(codicematricola) AS num
        FROM   fashion..matricole
        WHERE  (( stato = 120
                  AND mag1_id = 264 )-- vedere commento del 04/08/2006
               )
               AND scaricata = 0
               AND annullatalogicamente = 0
               AND articolo_id = @Articolo_ID
               AND mag2_id = mag1_id) t 
```

5. Use **EXISTS** instead of **LEFT OUTER JOIN** inside the WHERE condition between tables that have the PRIMARY KEY as NULL (https://explainextended.com/2009/09/15/not-in-vs-not-exists-vs-left-join-is-null-sql-server/).

6. Use the **CLUSTERED** index on the **PRIMARY KEY** when is needed. It is preferable to have the PK created with a single column (int or bigint) with ascendant values.

7. Avoid using **ORDER BY** inside the SELECT, **unless** using with the clause **TOP** or **PARTITION BY**.

8. If the PK is defined as **UNIQUEIDENTIFIER**, the table must have the default value defined as **NEWSEQUENTIALID()**.

9. Inside the Store Procedures, use Temp Tables instead of Table Vars , except the Sored Procedures called by BizTalk .

10. Avoid UDF usage.

11. The star **{*}** character inside any SELECT statement is forbidden.

12. If a query has a lot of **LEFT OUTER JOIN** on the same table, check if the query may be rewritten  using the **PIVOT** operator.

13. When you have a query with a IN clause with a lot of values or an unknown list of values, do a bulk insert on a temporary table and use an INNER JOIN instead of the IN clause.

14. When doing massive **INSERT**, create the index after the process is completed.

15. During a performance tuning activity, try first to use  existing indexes before building new ones.

16. **APPEND ONLY** pattern is deprecated.

17. Evaluate the usage of sp_getapplock instead of table semaphores.

18. Never use CURSOR (https://www.simple-talk.com/sql/t-sql-programming/rbar-row-by-agonizing-row/)

19. Pre **ANSI-92** syntax for the joins are forbidden,
for example:
```sql
[…]FROM TabA, TabB WHERE TabA.id = TabB.id AND TabA.AttrA = val
 
-- Needs to be converted in:
 
[…]FROM TabA JOIN TabB ON TabA.id = TabB.id WHERE TabA.AttrA = val
```

## Only OLAP

1. Tables load must be implemented  using the minimal logging (Prerequisites)
    * Each table must have a clustered index
    * The clustered index’s values must be incremental  (ascending or descending)
    * Where it is not possible to have incremental clustered index ,insert operations must be done with records sorted incrementally sorted
2. Tables could  also have one or more non-clustered indexes, if necessary
    * Before every table load operations, not-clustered indexes should be disabled
    * At the end of table load operations , non-clustered indexes must be rebuilt ( ?? – oppure basta solo reorganize ??)
3. After the loading operations the clustered index must be rebuilt (????? – da discutere – Fact ??)
4. Encourage where possible tables incremental loading
5. Avoid partial load of tables and the subsequent updates, where possible
    * If this is not always possible,  rebuild the indexes when the load procedure is completed
6. when you can use table partitioning, while avoiding the partition of fields which are then updated
    * update the partitioning field can cause the moving records from partitions (???? – non l’ho capito)
7. The row hash calculation on tables is mainly done on SQL Server
    * We need to improve the memory work, avoiding unnecessary movements of rows (??? – non l’ho capito)