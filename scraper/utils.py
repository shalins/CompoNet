from constants import SAVE_FILE_PREFIX, SAVE_FILE_SUFFIX

#
# Class Funtions
#

def read_file_as_string(filename):
    """Returns contents of textfile as string.
    
    Opens file with readonly permission, reads the 
    text and filters out tabs and newlines, and 
    returns the result string.
    """
    with(open(filename, 'r')) as txt:
        return txt.read().replace('\n', '').replace('\t', '')

def save_data(data, filepath):
    with(open(filepath, 'w')) as outfile:
        json.dump(data, outfile)
        
def create_data_filename(component_type, f1_cat, f1_idx, f1_val, f2_cat, f2_idx, f2_val, page):
    # We want the file to look something like: 
    # [COMPONENT]_[TYPE]_[FILTER_CATEGORY]_[FILTER_VALUE].json 
    # This means something like capacitor_ceramic_capacitance_2.2e-12.json
    return f"{SAVE_FILE_PREFIX}_{component_type}_{f1_cat}_idx_{f1_idx}_{f1_val}_{f2_cat}_idx_{f2_idx}_{f2_val}_start_{page}.{SAVE_FILE_SUFFIX}"