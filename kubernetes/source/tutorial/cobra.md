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

  