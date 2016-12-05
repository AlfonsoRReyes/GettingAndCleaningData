README

------



>  You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.



This document explains how the scripts and function work all together; what each of the functions accomplish; how the datasets are constructed in order to provide the solution; how the work can be replicated by going through the code.

# The main script

The main script is `run_analysis.R`. All the functions included in this script. There is no other additional script beside the main script.

# The main functions

`run_ana()`

​	This is the caller of all other functions. This function performs these tasks:

* Process the variables names of the file `features.txt` in order to produce valid, understandable, nice variables with no duplicates whatsoever. The function called is `compose_features()` and returns the valid names for the training and test datasets.
* Reads the activity labels from the file `activity_labels.txt`. 
* Reads the measurement datasets for training and testing using a common function called `compose()`. The datasets will return all processed: with valid variable names added, merged with activities records showing the description, and subject records for each of the datasets read from the files `x_train.txt` and `x_test.txt`.
* Performs the merge of the two datasets: training and test, producing a final tidy data set as required by the assignment.



`compose()`

​	This is a common function that acts on the training and test datasets. Given the fact that all of the tasks being performed over the datasets are identical, this function can accomplish the following tasks with no redundancy:

* Read the raw measurement datasets for training and testing.
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

`getFromLast()`: gets the first or second elements -counting from the end-, of a decomposed string. The decomposition is required in order to read the `bins window` in the duplicate rows. These variable names end in number such as `VariableName-9-16` or  `VariableName-1-16` or  `VariableName-1-24` 

​	