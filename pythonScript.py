import os;
import zipfile;
import re;
def traverse_all_directories(directory):
    zip_pattern =re.compile('.*\.zip$')
    files = [f for f in os.listdir('.') if os.path.isfile(f)]
    for filename in files:
        #print(filename);
        if(zip_pattern.match(filename)):
            print(filename);
            extract_zip(filename,"extracted");

def traverse_with_os_walk ():
    zip_pattern =re.compile('(.*)\.zip$')
    cpp_pattern =re.compile('(.*)\.cpp$')
    rootDirectory = os.getcwd();
    for root, dirs, files in os.walk(rootDirectory, topdown= True):
        for filename in files:
            zipMatch = re.search(zip_pattern,filename)
            cppMatch = re.search(cpp_pattern,filename)
            if(zipMatch):
                filename_without_extension=zipMatch.group(1)
                full_path_of_file=os.path.join(rootDirectory,root,zipMatch.group(0))
                extract_directory=os.path.join(rootDirectory,root,filename_without_extension)
                extract_zip(full_path_of_file,extract_directory);
                dirs.append(filename_without_extension)
            elif(cppMatch):
                full_path_of_file=os.path.join(rootDirectory,root,cppMatch.group(0))
                print (full_path_of_file);


        
def extract_zip (source,destination):
    #print("Extracting "  + source + " to  " + destination)
    with  zipfile.ZipFile(source,'r') as zf:
        zf.extractall(destination);

if __name__ == "__main__":
	#traverse_all_directories();
    traverse_with_os_walk();
