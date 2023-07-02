package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

// 在aria2c下载完成的时候调用这个脚本
// 将下载的文件从 ssd 移动到 hdd
func main() {

	// 接受3个参数：GID,file_counts,first_file_path
	// gid := flag.Args()[0]
	flag.Parse()
	if len(flag.Args()) <= 2 {
		fmt.Println("args is less than 2:" + string(rune(len(flag.Args()))) + ", not file download ")
		return
	}
	file_count := flag.Args()[1]
	first_file_path := flag.Args()[2]

	// file_count := "1"
	// first_file_path := "/root/Download/[织梦字幕组][总之就是非常可爱 第二季 トニカクカワイイ S2][10集][720P][AVC][简日双语].mp4"

	fmt.Println("file_count: " + file_count)
	fmt.Println("first_file_path: " + first_file_path)

	// 文件路径判空
	if first_file_path == "" {
		fmt.Println("first_file_path is empty, return")
		return
	}

	// 判断文件数是否为零
	if file_count == "" {
		fmt.Println("file_count is empty, return")
		return
	}

	file_count_num, err := strconv.Atoi(file_count)
	if err != nil {
		fmt.Println("file_count is not i:", err)
		return
	}
	if file_count_num <= 0 {
		fmt.Println("file_count_num <= 0, retrun")
		return
	}
	fmt.Printf("file_count_num is %d\n", file_count_num)

	// 源文件夹
	source_folder := "/aria2/ssd/"
	// source_folder := "/root/Download/"

	// 目标文件夹
	target_folder := "/aria2/hdd/"

	// 要移动的文件路径
	var source_file string
	var target_file string

	// 判断下载的文件是文件夹还是单个文件

	fmt.Printf("file_count_num[%d] is not 1, find up folder\n", file_count_num)
	file_paths := strings.Split(first_file_path, "/")
	if len(file_paths) >= 3 {
		fmt.Printf("file_paths has %d /\n", len(file_paths))
		source_file = source_folder + file_paths[3]
		target_file = target_folder + file_paths[3]
		fmt.Println("source_file: " + source_file)
	} else {

		fmt.Println("first_file_path not right, return")
		return
	}

	if source_file != "" {
		fmt.Println("start move form " + source_file + " to " + target_file)
		_, err := os.Stat(source_file)
		if err != nil {
			fmt.Println("source_file:"+source_file+"not exist", err)
			return
		}
		err = os.Rename(source_file, target_file)
		if err != nil {
			fmt.Println("move error, try copy", err)

			// 复制文件到目标文件夹中
			err := MoveFileExec(source_file, target_file)
			if err != nil {
				fmt.Println("move file error", err)
				return
			}

		}
		fmt.Println("move finish")
		fmt.Println("chomd start")
		cmd := exec.Command("chmod", "-R", "o+w", target_file)
		err = cmd.Run()
		if nil != err {
			fmt.Println("chmod fail", err)
			return
		}
		fmt.Println("chmod finish")
	} else {
		fmt.Println(source_file + " is empty")
	}

}

func MoveFileExec(source_file string, target_file string) error {
	// source_file_Path := strconv.Quote(source_file)
	// target_file_Path := strconv.Quote(target_file)
	fmt.Println("run command: mv " + source_file + " " + target_file)
	cmd := exec.Command("mv", source_file, target_file)
	err := cmd.Run()
	return err
}

func MoveFile(sourcePath, destPath string) error {
	inputFile, err := os.Open(sourcePath)
	if err != nil {
		return fmt.Errorf("Couldn't open source file: %s", err)
	}
	outputFile, err := os.Create(destPath)
	if err != nil {
		inputFile.Close()
		return fmt.Errorf("Couldn't open dest file: %s", err)
	}
	defer outputFile.Close()
	_, err = io.Copy(outputFile, inputFile)
	inputFile.Close()
	if err != nil {
		return fmt.Errorf("Writing to output file failed: %s", err)
	}
	// The copy was successful, so now delete the original file
	err = os.Remove(sourcePath)
	if err != nil {
		return fmt.Errorf("Failed removing original file: %s", err)
	}
	return nil
}
