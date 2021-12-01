/*
Cleaning Data in SQL Queries
*/

SELECT *

FROM SQL_Practice..nashville_housing

---------------------------------------------------------------------------------------------------------------
-- Ensure you are using the right Database for scripting

USE SQL_Practice

---------------------------------------------------------------------------------------------------------------
-- Standardize Date Format (Remove 2016-03-15 00:00:00:000, the 0s at the back)

SELECT 
	SaleDate, CONVERT(Date, SaleDate)
FROM SQL_Practice.dbo.nashville_housing -- OR


ALTER TABLE nashville_housing
ADD SaleDateConverted Date;

UPDATE nashville_housing -- Update the table with new formatted Date
SET SaleDateConverted = CONVERT(Date, SaleDate) 

SELECT 
	SaleDate, SaleDateConverted
FROM SQL_Practice.dbo.nashville_housing

-----------------------------------------------------------------------------------------------------------------
-- Populate Property Address Data (Because some ParcelID has duplicates which is same as PropertyAddress, populate up the duplicate to ensure is the same)

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM SQL_Practice..nashville_housing A
JOIN SQL_Practice..nashville_housing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] != B.[UniqueID ]
WHERE A.PropertyAddress is null -- MAKE SURE TO RUN THIS QUERY AGAIN TO CHECK IF STILL GOT NULL!

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM SQL_Practice..nashville_housing A
JOIN SQL_Practice..nashville_housing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] != B.[UniqueID ]
WHERE A.PropertyAddress is null

-------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State) USING SUBSTRING & PARSENAME

SELECT PropertyAddress
FROM SQL_Practice..nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS address, CHARINDEX(',', PropertyAddress) -- find character numbers till comma
FROM SQL_Practice..nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS address -- -1 will remove the comma
FROM SQL_Practice..nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS address -- Start after comma and end at total number of character of LEN
FROM SQL_Practice..nashville_housing

ALTER TABLE nashville_housing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE nashville_housing
ADD PropertySplitCity NVARCHAR(255);

UPDATE nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM SQL_Practice..nashville_housing


-- USING PARSENAME --

SELECT OwnerAddress
FROM SQL_Practice..nashville_housing

SELECT 
PARSENAME(OwnerAddress, 1) -- **PARSENAME works thing backwards from RIGHT to LEFT
FROM SQL_Practice..nashville_housing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM SQL_Practice..nashville_housing

ALTER TABLE nashville_housing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE nashville_housing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE nashville_housing
ADD OwnerSplitState NVARCHAR(255);

UPDATE nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM SQL_Practice..nashville_housing


-------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldAsVacant) -- Will output N, Yes, Y, No
FROM SQL_Practice..nashville_housing


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM SQL_Practice..nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT	
	SoldAsVacant, 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM SQL_Practice..nashville_housing
WHERE SoldAsVacant = 'Y' OR SoldAsVacant = 'N'

UPDATE nashville_housing
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

SELECT *
FROM SQL_Practice..nashville_housing


-----------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates *PARTITION BY THINGS WHICH IS UNIQUE*

WITH RowNumCTE AS (
SELECT
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID) AS row_num -- will group SAME ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference tgt and provide index no. for duplicates
FROM SQL_Practice..nashville_housing
)
DELETE *
FROM RowNumCTE
WHERE row_num > 1 -- >1 is finding the duplicates


---------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

ALTER TABLE nashville_housing
DROP COLUMN SaleDate

SELECT *
FROM SQL_Practice..nashville_housing
