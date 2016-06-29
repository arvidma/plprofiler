PL Profiler Examples
====================

It is assumed that anyone, interested in profiling complex PL/pgSQL code, is familiar with performance testing in general and performance testing of a PostgreSQL database in particular. Therefore it is also also assumed that the reader has a basic understanding of the pgbench utility.

The example test case
---------------------

All examples in this documentation are based on a modified pgbench database. The modifications are:

* The SQL queries, that make up the TPC-B style business transaction of pgbench, have been implemented in a set of PL/pgSQL functions. Each function essentially performs only one of the TPC-B queries. This is on purpose convoluted, since for demonstration purposes we want a simple, yet nested example. The function definitions can be found in [examples/pgbench_pl.sql](pgbench_pl.sql.md).
* A custom pgbench, found in [examples/pgbench_pl.profile](pgbench_pl.profile.md), is used with the -f option when invoking pgbench. 
* The table pgbench_accounts is modified.
    * The filler column is expanded and filled with 500 characters of data.
    * A new column, `category interger` is added in front of the aid and made part of the primary key.
	
The modifications to the pgbench_accounts table are based on a real world case, encountered in a customer database. Our case of course is greatly simplified. In the real world case the access to the table in question was in a nested function, 8 call levels deep, and the table had 10 indexes to choose from.

The problem, produced by these modifications, is as follows. The TPC-B transaction accesses the table based on the aid value alone, so that is the only key part available in the WHERE clause. However, since the table rows are now >500 bytes wide and the index is rather small, compared to that, the PostgreSQL query optimizer will choose an index scan.

```
pgbench_plprofiler=# explain select abalance from pgbench_accounts where aid = 1;
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..18484.43 rows=1 width=4)
   Index Cond: (aid = 1)
```

Since the first column of the index is not part of the index condition, this results in a full scan of the index! But that detail is nowhere visible. If we look at pg_stat_user_tables after a benchmark run, for example, it only tells us that all access to pgbench_accounts was done via index scans and that all those scans returned a single row. One would normally think that is good. 

On top of that, since the queries accessing the table will never show up in any statistics, we will never see that each of them takes 30ms already on a 10x scaling factor.

The full script to prepare the pgbench test database is found [here](prepdb.sh.md).

Executing SQL using the plprofiler utility
------------------------------------------

