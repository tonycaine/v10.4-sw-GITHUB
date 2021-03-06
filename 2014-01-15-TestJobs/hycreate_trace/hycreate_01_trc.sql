/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [TextData]
      ,[Duration]
      ,[StartTime]
      ,[EndTime]
      ,[Reads]
      ,[Writes]
      ,[CPU]
	  FROM [PerfData].[dbo].[temp_trc]
  where 
  [Duration] > 0 and textdata is not null
  order by starttime  

-- select as seen in the profile
SELECT * FROM [dbo].[SITE] [A]    ORDER BY [A].[STATION]

-- better use of the index
SELECT * FROM [dbo].[SITE] 
