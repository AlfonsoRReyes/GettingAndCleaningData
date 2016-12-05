# CodeBook.md

# About the data

## Subjects and Activities
The experiments have been carried out with a group of `30 volunteers` within an age bracket of 19-48 years. Each person performed six activities (`WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING`) wearing a smartphone.

## Subjects for training and testing
The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data. 

## ACtivity labels
```
1 WALKING
2 WALKING_UPSTAIRS
3 WALKING_DOWNSTAIRS
4 SITTING
5 STANDING
6 LAYING
```

# Constructing the data sets for analysis

## Read the variables names

### do all the features are unique

### add a column to mark duplicates

### what are the columns that are repeating


# Transformations

## Dealing with the repeating columns
We find that there are 3 groups of variables:

* fBodyAcc-bandsEnergy
* fBodyAccJerk-bandsEnergy
* fBodyGyro-bandsEnergy

Each of this variables have 42 energy measurements on three different windows (w1, w2, w3), and on three different axis (X, Y, Z). These variables need to be renamed accordingly to avoid repeating name of the columns.

The windows have different resolutions: `w1` has 8 steps bins like this: 1-8, [9, 16], [17, 24], [25, 32], [33, 40], [41, 48], [49, 56] and [56, 64]. `w2` has a 16 steps bins: [1, 16], [17, 32], [33, 48] and [49, 64]. `w3` has a step of 24 bins: [1, 24] and [25, 48]; id doesn't go up to 64.

These three windows (w1, w2, w3) read over the X, Y and Z axis. To differentiate the repeating columns we will have to add the axis to each of the windows.

### find if any column is repeating now

## Assign descriptive names to train data set

## Keep only mean and std-dev variables

## Read activitiy labels

## Read activities dataset

## Read subjects dataset

## Merging datasets
This action has 3 parts:

1. Merging the train_activities table with the activities table (with descriptive names)

2. Merging the joined table above (train_activities_inner) with the train measurments dataset.

3. Merging the subjects table with train table


# Getting the data

## Acquiring the datasets

We start by downloading the zipped file containing all the datasets and associated files.
We load the library `downloader` to allow us the use of the function `download()`.

Since we want to make this analysis reproducible, we added the capability of detecting if the folder `data` exists in the folder structure. If it doesn't exist, the script will create it for the user. Downloading and extracting the files will take few minutes.


```r
library(downloader)

if(!file.exists("./data")){dir.create("./data")}

fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

download(fileUrl, dest="dataset.zip", mode="wb") 
unzip ("dataset.zip", exdir = "./data")
```

