# run_analysis.R

run_ana <- function() {
  # main function
  # This function will perform these tasks:
  # merge the training and test datasets
  # read train
  # read test
  # add variable <source> to each data set to identify the original table
  # merge train and test
  # read variable names from features table
  # assign variable names to merged table
  # create valid names
  # assign valid names to merged table
  # Extract only the man and std-deviation
  # choose only mean and std-dev variables
  # Use descriptive names for activities
  # read and assign activities
  # read and assign subjects
  # --------------------------------------------------------------------------
  library(dplyr)
  library(stringr)
  
  # load measurement data files
  
  # train
  train_measurements_raw <- raw_measurements_data("train")$measurements
  train_activities_raw   <- raw_measurements_data("train")$activities 
  train_subjects_raw     <- raw_measurements_data("train")$subjects 
  
  # test
  test_measurements_raw <- raw_measurements_data("test")$measurements
  test_activities_raw   <- raw_measurements_data("test")$activities 
  test_subjects_raw     <- raw_measurements_data("test")$subjects 
  
  # load variable names or features
  # read variable/column names. Also called features. 561 elements.
  # rows:  561. Matches the number of columns in the measurement datasets
  # V1:    record number
  # V2:    variable name or feature
  fileName <- "./data/UCI HAR Dataset/features.txt"
  features <- read.table(fileName)
  
  # ensure valid names for the variables. 
  # rows:             561
  # columns:          1 (returning as character vector)
  # name of column:   nice
  # characteristics:  variable names. No parentheses, no duplicates, no dashes, no dots
  valid_column_names <- compose_features(features)
  
  # read activity labels. They are 6 activity label variables
  # rows: 6
  # V1:   activity ID
  # V2:   activity description
  # file: "./data/UCI HAR Dataset/activity_labels.txt"
  activity_labels <- read.table("./data/UCI HAR Dataset/activity_labels.txt")
  
  # assign correct variable names to measurement data frames
  # add column names to measurements. assign features to variables in measurements datasets
  train_measurements <- assign_valid_names(train_measurements_raw, valid_column_names)
  test_measurements  <- assign_valid_names(test_measurements_raw,  valid_column_names)
  
  # Keep only mean and std-dev variables in measurements dataset 
  
  keywords <- c("mean", "std")
  train_measurements_select <- select_columns_with_expression(train_measurements, keywords)
  test_measurements_select  <- select_columns_with_expression(test_measurements,  keywords)
  

  
  # add activity labels to raw acitivities
  train_activities_with_labels <- merge_activity_labels(train_activities_raw, activity_labels)
  test_activities_with_labels  <- merge_activity_labels(test_activities_raw,  activity_labels)
  
  # merge measurements, activities and subjects
  train_merged <- merge_all(train_measurements_select, train_activities_with_labels, train_subjects_raw)
  test_merged  <- merge_all(test_measurements_select,  test_activities_with_labels,  test_subjects_raw)
  
  # merge the measurement datasets for training and testing
  # rows:     10299
  # columns:  92
  # contains: (1) measurements for training and tests; (2) subjects; (3) activities
  train_test_merged <<- rbind(train_merged, test_merged) %>%
    mutate(row_num = row_number())      # add row_num to be able to reorder table in the future
  
  # assignment question: group by subjects and activities summarizing selected columns by the mean
  # data frame: train_test_merged
  # group by subjects and activities
  by_SubjectActivity <- group_by(train_test_merged, subjects_id, activity_name)
  
  # summary showing the mean of mean and std columns by subjects and activities
  # acting on the merged measurement data frames
  # assign select variable names (mean, std) to a vector
  mean_std_vars <- get_variables_matching_keywords(valid_column_names, keywords)
  
  # summary
  sum_SubjectActivity <<- summarize_at(by_SubjectActivity, .cols = mean_std_vars,
                                       .funs = mean)  
  
  # output of tidy dataset containing summary of subjects and activities 
  # and the mean of selected columns.
  write.table(sum_SubjectActivity, "sum_subjects_activities.txt")
  
}


get_variables_matching_keywords <- function(column_names, keywords) {
  # get a vector of variable names that match the keywords
  # Called by: run_ana()
  matchExpression <- paste(keywords, collapse = "|")
  select_columns <- column_names[grep(matchExpression, column_names)]
  return(select_columns)
}


merge_all <- function(measurements, activities, subjects) {
  # merge all measurements, activities and subjects in one data frame
  
  # add row number variable to subjects table. It will be useful to check the merge or join later
  subjects <- subjects %>%
    mutate(subjects_rownum = row_number()) %>%          # row numbering to column
    rename(subjects_id = V1)                            # rename column
  
  # add a row number column to measurements to be sure it is not sorted by the merge operation
  measurements <- measurements %>%
    mutate(m_rownum = row_number()) %>%   # add a record number to measurements
    select(m_rownum, everything())        # move the row_num column to be the first column
  
  # merge measurements with activity table
  m0 <- cbind(activities, measurements)
  
  # merge new table above with subjects table
  final <- cbind(subjects, m0)
  rm(m0) 
  
  ds_name <- ifelse(nrow(measurements) == 7352, "train", "test")
  
  # add a variable to identify the source of the data
  final <- final %>%
    mutate(source = ds_name) %>%                                                                 # new column for source
    # add new column combining source and record number
    mutate(src_rownum = paste0(source, "_", str_pad(as.character(m_rownum), 5, pad = "0"))) %>%  # add column with source and row num
    select(-c(m_rownum, activity_rownum, subjects_rownum))                                       # remove utility columns
  
  # return processed dataframe
  return(final)
}


merge_activity_labels <- function(activities_df, activity_labels) {
  # merge the activity labels with activities measured (train or test)
  # Called by: main()
  #
  
  # add row numbers to activity table. It will be useful to check the merge or join later
  activities_df$activity_rownum <- 1:nrow(activities_df)      # row numbering to column
  activities_df <- rename(activities_df, activity_id = V1)    # rename column
  
  # merge the activity tables (long and descriptive) keeping the original order of test_activity
  activity_merged <- dplyr::inner_join(activities_df, activity_labels, by =c( "activity_id" = "V1"))
  activity_merged <- dplyr::rename(activity_merged, activity_name = V2) # rename columns
  
  return(activity_merged)
}


select_columns_with_expression <- function(df, keywords) {
  # select only the columns that match the keywords
  # Keep only mean and std-dev variables in measurements dataset 
  matchExpression <- paste(keywords, collapse = "|")                           # pattern of keywords mean, std
  df_ret <- select(df, matches(matchExpression, ignore.case = TRUE))   # select columns that match mean, std
  return(df_ret)
}


assign_valid_names <- function(df, new_names) {
  # assign correct variable names to a data frame (train or test)
  # Called by: run_ana()

  names(df) <- new_names      # assign column names
  return(df)       
}


raw_measurements_data <- function(ds_name) {
  # read all raw measurement data sets
  # it will return a list that will be parse in the main function
  
  # filenames
  measurements_fn <- "./data/UCI HAR Dataset/file/X_file.txt"
  activities_fn   <- "./data/UCI HAR Dataset/file/y_file.txt"
  subjects_fn     <- "./data/UCI HAR Dataset/file/subject_file.txt"
  
  # replace <file> by <train> or <test>
  ds_files_v <- c(measurements_fn, activities_fn, subjects_fn)   # a vector of files to read
  ds_files   <- gsub("file", ds_name, ds_files_v)                # switch the identifier "_file" by "_train" or "_test"
  
  # this will make the list more readable
  mea <- read.table(ds_files[1])
  act <- read.table(ds_files[2])
  sub <- read.table(ds_files[3])
  
  return(list(measurements=mea, activities=act, subjects=sub))
}



compose_features <- function(df) {
  # takes care of the proper validation of the variables names in features
 
  features <- df
  
  # convert factors to character vector
  features <- features %>%
    mutate(V2 = as.character(V2))
  
  # get counts for all rows and duplicate rows
  all_rows <- nrow(features)
  duplicate_rows <- length(features$V2[(duplicated(features$V2) | duplicated(features$V2, fromLast = TRUE))])
  list(all_rows=all_rows, duplicates=duplicate_rows)    # create a list for nice reporting later
  
  # create features with logical marker for duplicates
  features2 <- features %>%
    mutate(duplicate = FALSE) %>%    # mark the whole new column as FALSE
    mutate(duplicate = (duplicated(V2) | duplicated(V2, fromLast = TRUE)))  # mark TRUE duplicates
  
  # get subset of features. working only with subset of duplicates
  
  getFromLast <- function(y, m) {
    # function that gets the first or second elements -counting from the end-, of a decomposed string
    pat <- "\\,|\\-"                   # pattern is a comma or a dash
    var_list <- strsplit(y, pat)       # split the string by the pattern
    last2 <- data.frame(t(data.frame(sapply(var_list, tail, n=2))))     # get the last two elements of the list
    as.character(last2[, m])    # get character vector all rows, column "m"
  }
  
  fill_axis <- function() {
    # fill rows with corresponding measurement axis
    # get a vector of X, Y, Z every fourteen
    x <- rep("x", 14); y <- rep("y", 14); z <- rep("z", 14); 
    xyz <- rep(c(x,y,z), 3)  
  }
  
  
  # operate on a dataframe of duplicates only
  features_dup <- features2 %>%
    filter(duplicate == TRUE) %>%      # duplicate features or column names
    mutate(lbin = as.integer(getFromLast(as.character(V2), 1))) %>%    # get the first bin set
    mutate(rbin = as.integer(getFromLast(as.character(V2), 2))) %>%    # get the second bin set
    mutate(window = ifelse(abs(lbin-rbin)+1 == 8, "w1", 
                           ifelse(abs(lbin-rbin)+1 == 16, "w2", 
                                  ifelse(abs(lbin-rbin)+1 == 24, "w3", "")))) %>%   # assign the bin windows
    mutate(axis = fill_axis()) %>%                                                  # assign the axis labels
    mutate(V2_new = paste(V2, window, axis, sep="-")) %>%                           # form the full name of the new column
    select(V1, V2_new)                                                              # select the id and the new column name
  
  # merge the original dataframe with the duplicates dataframe
  features_new <- merge(features2, features_dup, by.x = "V1", by.y = "V1", all = TRUE)
  features_new <- mutate(features_new, V2_new = ifelse(duplicate == FALSE, as.character(V2), V2_new))
  
  # convert factors to character vector
  raw_column_names <- as.character(features_new$V2_new)
  
  # ensure there are valid names for the variables. Making valid_column_names GLOBAL
  valid_column_names <- make.names(names=raw_column_names, unique=TRUE, allow_ = TRUE)
  features_new$V2_valid <- valid_column_names
  
  # convert clean features dataframe to nice variables: no dots, no parentheses, no dash
  nice_variables <- make_nice_variables(features_new$V2_valid)
  features_new$V2_nice <- nice_variables
  
  # find if there are duplicate rows
  duplicate_rows <- duplicates(features_new$V2_nice)
  
  # set new names to final dataframe
  features_new <- features_new %>%      # proceed to rename to something human
    rename(original = V2, isduplicate = duplicate, nonduplicate = V2_new, make = V2_valid, nice = V2_nice)
  
  features_new$nice    # return only one column
}


make_nice_variables <- function(column_names) {
  # Called by:         compose_features()
  #
  # Use recommendations for variable names
  # no dots, no dashes, no underscores, no capitalization, no uppercase
  #
  # column_names: character vector
  #               a vector or table column
  # return:       character vector
  var_names <- as.character(column_names)      # convert from factors to character type
  splitNames <- strsplit(var_names, "[.]")     # split in the dot
  s <- sapply(splitNames, noblankElements)     # apply function noblankElements to the list to get nice variable names
}


noblankElements <- function(x) {
  # Called by:     make_nice_variables()
  #
  # receives a list of characters that has been split
  # and returns the concatenation of not-blank elements in lowercase
  #
  # x:        character vector
  # returns:  character vector
  (x[(!is.null(x)) & (x != "")]) %>%    # get non empty elements and non blanks in the list
    unlist() %>%                        # unpack the elements in the list
    tolower() %>%                       # convert to lowercase
    paste(collapse = '')                # concatenate valid components of original variable name
}


duplicates  <- function(vec) {
  # Called by: compose_features()
  #
  # Detects variable names that are duplicate
  #
  # vec:     character vector or column from a table to analyze
  # return:  integer
  #          number of rows that are duplicate
  duplicate_rows <- length(vec[(duplicated(vec) | duplicated(vec, fromLast = TRUE))])  
}



