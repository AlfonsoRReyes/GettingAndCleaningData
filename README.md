README

------



>  Instructions: You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.



This document explains how the scripts and function work all together; what each of the functions accomplish; how the datasets are constructed in order to provide the solution; how the work can be replicated by going through the code.

# The main script

The main script is `run_analysis.R`. All the functions included in this script. There is no other additional script beside the main script. 

The script has abundant comments documenting what each part of the code does. Some comments are above sections of the code qualified as important, while the comments on the side document an operational secondary task.

All of the files have been read using `read.table()`. Data frame operations have used mostly the `dplyr` library. 



# The output summary file

This is a data file generated according to requirements of the assignment. It is an independent tidy data set with the average of each variable for each activity and each subject. The variables that are part of this table are only the mean and standard deviation. Originally, the dataset has 561 variable but are reduced to 88 variables after making the selection of columns containing the keywords `mean` and `std`.

The independent tidy data set is in the repository and was created with this command:

`write.table(sum_SubjectActivity, "sum_subjects_activities.txt")`

To read it back for further analysis the following could be used if the file is local or has been downloaded:

`sum_subjects_activities_txt <- read.table("sum_subjects_activities.txt")`



To read the file directly from the repository use this command instead:

```
fileUrl <- "https://github.com/AlfonsoRReyes/GettingAndCleaningData/raw/master/sum_subjects_activities.txt"

sum_subjects_activities_url <- read.table(fileUrl)
```



The data frame will show 180 observations and 88 variable names. The 180 observations result from 30 individuals who performed separate training and testing experiments, each performing 6 activities. meaning, there will be 6 summarized observations per individual.

The measurement variables are all the mean of the 88 variable that were pre-selected as measurements of the mean and standard deviation of other measurements. The meaning of these variables is explain in the __codebook__, which can also be found in the repository.



# The main functions

`run_ana()`

​	This is the main caller of all other functions. This function performs these tasks:

* Reads the zipped file URL for all the datasets and unzips it to the folder `data`.
* Process the variables names of the file `features.txt` in order to produce valid, understandable, nice variables with no duplicates whatsoever. The function called is `compose_features()` and returns the valid names for the training and test datasets.
* Reads the activity labels from the file `activity_labels.txt`. 
* Reads the measurement datasets for training and testing using a common function called `compose()`. The datasets will return all processed: with valid variable names added, merged with activities records showing the description, and subject records for each of the datasets read from the files `x_train.txt` and `x_test.txt`.
* Performs the merge of the two datasets: training and test, producing a final tidy data set as required by the assignment.



`compose()`

​	This is a common function that acts on the training and test datasets. Given the fact that all of the tasks being performed over the datasets are identical, this function can accomplish the following tasks with no redundancy:

* Read the raw measurement datasets for training and testing (`train` and `test`).
* Attach valid variable names to the measurement datasets.
* Select only the columns `mean` and `std` according to the assignment instructions.
* Merge the `activity` tables (long and descriptive) 
* Merge the `subjects` tables (long) 
* Add utility columns to the dataset for future identification and sorting. Utility columns are documented in the codebook.



`compose_features()`

​	This function takes care of the proper validation of the variables names. This is what happens inside this function:

* The file `features.txt` is read into a dataframe `features`.

* The number of duplicate variable names is found and assigned to the object `duplicate_rows`. The duplicates are marked into a dataframe called `features2` with a logical flag column called `duplicate`, which will take the value `FALSE` for a non-repeating variable name, and `TRUE` for a variable name that repeats.

* The duplicate variable names are processed in such a way that the duplication is detected and corrected. There are 126 duplicate variable names out of 561 total. These 126 variable names are corrected by adding their `bin window` and the corresponding `axis` for the observation. There are three axis: x, y and z. For instance, if this correction is not performed, then a variable name such as fnnxnxn() would repeat three times per axis, per bin window. There are 3 kinds of `bin windows` and 14 `bins per axis`. Since there are three axis, we end up with 14 x 3 x 3 = 126 variable names that are finally properly corrected.

* The 126 duplicate variable names are stored in a dataframe `features_dup` which will be used for processing: (1) get the `bin window` range which has three types of steps (8, 16 and 24); (2) calculate the step and apply the corresponding `bin window` name (w1, w2 or w3); (3) assign the `axis` to a column; (4) perform the concatenation of the original variable name with its corresponding `bin window` name and `axis`. 

* Make all the variable names, no-duplicates and duplicates, to conform to recommendations about variable names: no dots, no underscores, no dashes, in lowercase, no capitalization.

* The function will return only the column with the nice variable names although the processing dataframe `features_new` contains additional columns that enable the correction of the duplicates.

  ​

# Auxiliary functions

`getFromLast()`: gets the first or second elements -counting from the end-, of a decomposed string. The decomposition is required in order to read the `bins window` in the duplicate rows. These variable names end in number such as `VariableName-9-16` or  `VariableName-1-16` or  `VariableName-1-24`. This function reads these numbers delimited the comma and the dash. For each of these type of bins a window number is assigned: w1, w2 or w3. Called from `compose_features()`



`fill_axis()`:  fills  rows of duplicate variable names with their corresponding measurement axis. It will assign a vector of X, Y, Z every fourteen rows. Called from `compose_features()`



`make_nice_variables`: Use recommendations for variable names with no dots, no dashes, no underscores, no capitalization, no uppercase. Called from `compose_features()`	



`noblankElements`: receives a list of characters that has been split and returns the concatenation of not-blank elements in lowercase. Called from `make_nice_variables()`.



`duplicates()`: get the number of variable names that are duplicate.



# Main files used in assignment

`run_analysis.R`: the main script that has been explained above.

`features.txt`: file with the variable names in raw form. 561 observations, 2 variables.

`activity_labels.txt`: descriptive names for the activities. 6 observation, 2 variables.



## Files related to training

`x_train.txt`: training measurements dataset. 7352 observations, 561 variables.

`y_train.txt`: training activity dataset. 7352 observations, 2 variables.

`subjects_train.txt`: subjects IDs who performed the training. 7352 observations, 2 variables.



## Files related to tests

`x_test.txt`: tests measurements dataset. 2947 observations, 561 variables.

`y_test.txt`: tests activity dataset. 2947 observations, 2 variables.

`subjects_test.txt`: subjects IDs who performed the tests. 2947 observations, 2 variables.



# Data frames

Data frames have been profusely used in this assignment. We will start describing the data frames from the most important downwards:

`sum_SubjectActivity`: this data frame is a summary by subjects and activities as per requirements of the assignment. This data frame is based on the merged `train` and `test` data frame (10299 observations). It is resulting from applying the mean to selected columns that have in their variable names the keywords `mean` and `std`. This summary data frame has 180 observations and 88 variables, where the first grouping variable is `subjects_id` (values from 1 thru 30), and the second variable name `activity_name` (with values laying, sitting, standing, walking, walking_downstairs and walking_upstairs.)

`train_test_merged`: this is the resulting data frame after combining the training and test datasets. This final dataset contains 10299 observations and 92 variables. This data frame will later be used to produce the tidy dataset according to activity, subjects and the mean of the numerical variables (average and standard deviation) in the dataset.

`train`: it is a dataset before the merging operation with test. It has 7352 observations and 91 variables.

`test`: it is a dataset before the merging operation with train. It has 2947 observations and 91 variables.