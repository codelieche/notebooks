## Cobra的基本使用

> Cobra是Golang构建CLI命令行程序的库。
>
> https://github.com/spf13/cobra



### 基本使用

- 安装cobra：

  ```bash
  go get -u github.com/spf13/cobra/cobra
  
  go get github.com/spf13/cobra/cobra
  ```

- `cobra --help`:

  ```bash
  # cobra --help
  Cobra is a CLI library for Go that empowers applications.
  This application is a tool to generate the needed files
  to quickly create a Cobra application.
  
  Usage:
    cobra [command]
  
  Available Commands:
    add         Add a command to a Cobra Application
    help        Help about any command
    init        Initialize a Cobra Application
  
  Flags:
    -a, --author string    author name for copyright attribution (default "YOUR NAME")
        --config string    config file (default is $HOME/.cobra.yaml)
    -h, --help             help for cobra
    -l, --license string   name of license for the project
        --viper            use Viper for configuration (default true)
  
  Use "cobra [command] --help" for more information about a command.
  ```

### 简单示例

- 初始化个应用：`cobraApp`

  ```bash
  cd $GOPATH/src
  cobra init --pkg-name github.com/codelieche/goAction/kubernetes/tutorial/cobraApp github.com/codelieche/goAction/kubernetes/tutorial/cobraApp
  ```

  执行命令后，输出：

  > Your Cobra applicaton is ready at
  > ~/studydoc/kubernetes/source/src/github.com/codelieche/goAction/kubernetes/tutorial/cobraApp



- 添加子命令：

  ```bash
  cd github.com/codelieche/goAction/kubernetes/tutorial/cobraApp
  ```

  查看目录文件：

  ```bash
  ➜  cobraApp git:(master) ✗ tree      
  .
  ├── LICENSE
  ├── cmd
  │   └── root.go
  └── main.go
  ```

  添加子命令`run`:

  ```bash
  #  cobra add run
  run created at ~/studydoc/kubernetes/source/src/github.com/codelieche/goAction/kubernetes/tutorial/cobraApp
  ```

  再次查看目录：

  ```bash
  ➜  cobraApp git:(master) ✗ tree
  .
  ├── LICENSE
  ├── cmd
  │   ├── root.go
  │   └── run.go
  └── main.go
  
  1 directory, 4 files
  ```

  多了一个run.go的文件。

- `run.go`的源码

  ```go
  package cmd
  
  import (
  	"fmt"
  
  	"github.com/spf13/cobra"
  )
  
  // runCmd represents the run command
  var runCmd = &cobra.Command{
  	Use:   "run",
  	Short: "A brief description of your command",
  	Long: `A longer description that spans multiple lines and likely contains examples
  and usage of using your command. For example:
  
  Cobra is a CLI library for Go that empowers applications.
  This application is a tool to generate the needed files
  to quickly create a Cobra application.`,
  	Run: func(cmd *cobra.Command, args []string) {
  		fmt.Println("run called")
  	},
  }
  
  func init() {
  	rootCmd.AddCommand(runCmd)
  
  	// Here you will define your flags and configuration settings.
  
  	// Cobra supports Persistent Flags which will work for this command
  	// and all subcommands, e.g.:
  	// runCmd.PersistentFlags().String("foo", "", "A help for foo")
  
  	// Cobra supports local flags which will only run when this command
  	// is called directly, e.g.:
  	// runCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
  }
  ```

  

- 执行子命令：

  ```bash
  # go run main.go run     
  run called
  ```

- 修改下`run.go`

  ```go
  package cmd
  
  import (
  	"fmt"
  	"log"
  	"os/exec"
  	"strings"
  
  	"github.com/spf13/cobra"
  )
  
  var cmdString string
  
  // runCmd represents the run command
  var runCmd = &cobra.Command{
  	Use:   "run",
  	Short: "执行run命令",
  	Long: `执行run命令:
  传递想要执行的子命令，然后执行，比如：ls, pwd等.`,
  	// 传递的args的个数
  	Args: cobra.MinimumNArgs(0),
  	Run: func(cmd *cobra.Command, args []string) {
  		log.Println("run called")
  
  		//cmdString := strings.Join(args, " ")
  		log.Println("cmdString:", cmdString)
  		log.Println("args：", args)
  		if cmdString == "" {
  			cmdString = "ls"
  		}
  
  		commandString := cmdString
  		switch cmdString {
  		case "ls", "ls -a", "ls -al", "ls -l", "tree":
  			commandString = fmt.Sprintf("%s %s", cmdString, strings.Join(args, " "))
  		case "pwd":
  			commandString = "pwd"
  		default:
  			log.Println("当前执行的命令是：", cmdString, "不可执行")
  			return
  		}
  
  		log.Println("开始执行命令：", commandString)
  
  		// 执行命令并输出
  		cmdBash := exec.Command("/bin/bash", "-c", commandString)
  		if results, err := cmdBash.CombinedOutput(); err != nil {
  			fmt.Println("执行出错,", err.Error())
  			panic(err)
  		} else {
  			// 打印输出：byte
  			// fmt.Println(results)
  			fmt.Println(string(results))
  		}
  	},
  }
  
  func init() {
  	rootCmd.AddCommand(runCmd)
  	// 处理子命令相关的参数
  	runCmd.Flags().StringVarP(&cmdString, "command", "c", "ls", "执行bash的命令")
  
  }
  ```

- 再次测试：

  - 直接运行：

    ```bash
    # go run main.go run        
    2019/09/27 11:17:33 run called
    2019/09/27 11:17:33 cmdString: ls
    2019/09/27 11:17:33 args： []
    2019/09/27 11:17:33 开始执行命令： ls 
    LICENSE
    cmd
    main.go
    ```

  - 传入command参数：

    ```bash
    # go run main.go run --command=tree
    2019/09/27 11:18:29 run called
    2019/09/27 11:18:29 cmdString: tree
    2019/09/27 11:18:29 args： []
    2019/09/27 11:18:29 开始执行命令： tree 
    .
    ├── LICENSE
    ├── cmd
    │   ├── root.go
    │   └── run.go
    └── main.go
    
    1 directory, 4 files
    ```

  - 执行ls并传入args

    ```bash
    # go run main.go run --command="ls -al" ./cmd
    2019/09/27 11:19:49 run called
    2019/09/27 11:19:49 cmdString: ls -al
    2019/09/27 11:19:49 args： [./cmd]
    2019/09/27 11:19:49 开始执行命令： ls -al ./cmd
    total 16
    drwxr-x--x  4 alex.zhou  staff   128 Sep 27 11:15 .
    drwxr-xr--  5 alex.zhou  staff   160 Sep 26 20:52 ..
    -rw-r--r--  1 alex.zhou  staff  2767 Sep 27 10:08 root.go
    -rw-r--r--  1 alex.zhou  staff  2434 Sep 27 11:15 run.go
    ```

    