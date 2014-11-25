from __future__ import print_function
import os;
import zipfile;
import re;
import subprocess;


compilerDirectory="C:/\"Program Files (x86)\"/\"Microsoft Visual Studio 11.0\"/VC/bin/";
batFile="vcvars32.bat";

def compileFile(full_path,filename_without_extension,directory):

    compileCommand="cl/EHsc "+ addQuote(full_path);
    changeDirectoryCommand="cd " + compilerDirectory;
    combinedCommand = changeDirectoryCommand+"&&" + batFile+"&&"+compileCommand;
    moveCommand = changeDirectoryCommand + "&&" +"move " + addQuote(filename_without_extension+".exe")+" " + addQuote(directory);
    os.system(combinedCommand)
    os.system(moveCommand)

def addQuote(str):
    return '"'+str+'"'

def traverse_with_os_walk ():
    zip_pattern =re.compile('(.*)\.zip$')
    cpp_pattern =re.compile('(.*)\.cpp$')
    mainStartingDirectory = os.getcwd();
    for os_walk_root, dirs, files in os.walk(mainStartingDirectory, topdown= True):
        for filename in files:
            zipMatch = re.search(zip_pattern,filename)
            cppMatch = re.search(cpp_pattern,filename)
            if(zipMatch):
                filename_without_extension=zipMatch.group(1)
                full_path_of_file=os.path.join(mainStartingDirectory,os_walk_root,zipMatch.group(0))
                extract_directory=os.path.join(mainStartingDirectory,os_walk_root,filename_without_extension)
                extract_zip(full_path_of_file,extract_directory);
                dirs.append(filename_without_extension)
            elif(cppMatch):
                directory = os.path.join(mainStartingDirectory,os_walk_root)
                full_path_of_file=os.path.join(mainStartingDirectory,os_walk_root,cppMatch.group(0))
                filename_without_extension = cppMatch.group(1);
                compileFile(full_path_of_file,filename_without_extension,directory);
                
def createTestCaseFromSingleFile(filename):
    file = open (filename,"r");
    wholeFile=file.read();
    delimiter = "+\/+"
    outputFilename="INPUT";
    testCaseNumber = 0;
    testCases= wholeFile.split(delimiter);
    for testCase in testCases :
        caseInputs = testCase.split(",");
        print ( " printed one " )
        outputFile = open (outputFilename+str(testCaseNumber),"w");
        for input in caseInputs :
             print ( input.strip() , file = outputFile);
             print (input.strip());
        outputFile.close();
        testCaseNumber+=1;

def extract_zip (source,destination):
    #print("Extracting "  + source + " to  " + destination)
    with  zipfile.ZipFile(source,'r') as zf:
        zf.extractall(destination);

if __name__ == "__main__":
    #traverse_with_os_walk();
    createTestCaseFromSingleFile("delimitedInputs.txt");
