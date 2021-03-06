--Cleaning Data in SQL Queries

Select *
from PortfolioProject.dbo.NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------
--1)   Standardize Date Format

Select SaleDate
from PortfolioProject.dbo.NashvilleHousing  

--change and add a new column with the correct format of the date 

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

Select SaleDateConverted
from PortfolioProject.dbo.NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------
-- 2) Populate Property Address Data 

Select *
from PortfolioProject.dbo.NashvilleHousing
--where PropertyAddress is null   
order by ParcelID

--*WE NEED TO JOIN THE TABLE TO ITSELF  
Select *
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b 
 on a.ParcelID = b.ParcelID  
 AND a.[UniqueID ] <> b.[UniqueID ] 

 --* next step:
 Select a.ParcelID,a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b 
 on a.ParcelID = b.ParcelID  
 AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress is null  
 --we get 35 rows where property address is null

 --* next step:
 --we use ISNULL function to replace NULL with a specific value which we detirmine in the parenthesis
 --in this case: if the value is NULL in the a.PropertyAddress, the function will replace it with the value in the b.PropertyAddress column
 
 Select a.ParcelID,a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b 
 on a.ParcelID = b.ParcelID  
 AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress is null

 --* next step: update the table a and populate the data which has NULL values in the PropertyAddress column
 UPDATE a
 SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
 from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b 
 on a.ParcelID = b.ParcelID  
 AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress is null



 ------------------------------------------------------------------------------------------------------------------------------


 -- 3) BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)

 --3.1) Address, City
 
 Select PropertyAddress
 From PortfolioProject.dbo.NashvilleHousing   


 --we are going to use SUBSTRING and CHARACTER INDEX or CHAR INDEX to separate the address into two columns

 SELECT
 SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address  --a
 , SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City  --b
 From PortfolioProject.dbo.NashvilleHousing

 --* next step: ALTER AND UPDATE THE TABLE WITH ADDING THE TWO COLUMNS

 --*adds the COLUMN TO THE TABLE:
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

--*updates it with the result
Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) --a


--*adds the COLUMN TO THE TABLE:
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

--*updates it with the result
Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) --b

--*CHECK THE RESULT(far right)
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing



--3.2) ***Address, City and State*** in OwnerAddress and split it --USE DIFFERENT METHOD THAN ABOVE

--USE PARSE NAME -it only works with periods and in our column we have commas 

-- replace commas with periods
SELECT 
PARSENAME (REPLACE(OwnerAddress, ',','.'), 3) as Address,
PARSENAME (REPLACE(OwnerAddress, ',','.'), 2) as City,
PARSENAME (REPLACE(OwnerAddress, ',','.'), 1) as State
FROM PortfolioProject.dbo.NashvilleHousing


--* next step: ADD THIS AS NEW COLUMNS TO THE TABLE

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',','.'), 1)

--* next step: CHECK THE RESULT(far right)
Select * 
FROM PortfolioProject.dbo.NashvilleHousing



------------------------------------------------------------------------------------------------------------------------------


--4.) change Y and N to YES and NO in "Sold as Vacant" column

--check the distinct values in "Sold as Vacant" column
Select Distinct(SoldAsVacant) 
FROM PortfolioProject.dbo.NashvilleHousing

--result is 4 distinct value: (N, Yes, Y, No)

--*change them to Yes and No throughout the whole column to be uniform
--CASE STATEMENT
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM PortfolioProject.dbo.NashvilleHousing

--update
Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END

--CHECK if it worked with counting the distinct values

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2  --it worked 

------------------------------------------------------------------------------------------------------------------------------

--5) Remove Duplicates with CTE
WITH RowNumCTE AS(
select *,
  ROW_NUMBER () OVER (
  PARTITION BY ParcelID, 
  PropertyAddress, 
  SalePrice, 
  LegalReference
  ORDER BY UniqueID) row_num      
FROM PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
DELETE 
from RowNumCTE
WHERE row_num > 1
--order by PropertyAddress

---it deleted 121 rows that were duplicated 

------------------------------------------------------------------------------------------------------------------------------

--6) DELETE UNUSED COLUMNS



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerADDRESS, TaxDistrict, PropertyAddress, SaleDate

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

Select * 
from PortfolioProject.dbo.NashvilleHousing