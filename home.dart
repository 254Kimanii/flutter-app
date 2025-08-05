import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
class Home extends StatefulWidget {
  const Home({super.key});


  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final myTasks = Hive.box('mytasks');
 Map tasks =<String , bool>{
   
 };
 List<String> filterOptions = ['All Tasks', 'Completed', 'Pending'];
 String selectedFilter = 'All Tasks';

  final taskcontroller = TextEditingController();
  final edittaskcontroller = TextEditingController();
   
  bool _showtextfield = false;

  @override
  void dispose() {
      taskcontroller.dispose();
      edittaskcontroller.dispose();
      super.dispose();          
      }
  @override
  void initState() {
  super.initState();
  final savedTasks = myTasks.toMap().cast<String, bool>();
  tasks.addAll(savedTasks);
}


  @override
  Widget build(BuildContext context) {
     final taskkeys = tasks.keys.toList();
     
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('TO-DO APP', style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold
              ),),
              
            SizedBox(width: 20,),
            IconButton(onPressed: (){
              showDialog(context: context, builder:(context){
                return AlertDialog(
                  title: Text('Delete all tasks!'),
                  actions: [  
                    OutlinedButton(onPressed: (){
                      final deletedTasks = Map<String, bool>.from(tasks);
                      setState(() {
                        tasks.clear();
                        myTasks.clear();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Task deleted'),
                              action: SnackBarAction(label: 'Undo', onPressed: () {
                                setState(() {
                                  tasks = Map<String, bool>.from(deletedTasks); 
                                });
                              }),
                              )
                             );
                    }, child: Text('Yes')),
                    OutlinedButton(onPressed: (){
                      Navigator.pop(context);
                    }, child: Text('No'))
                  ],
                );
              });
            }, icon: Icon(Icons.delete_forever_sharp)),
            DropdownButton(
                value: selectedFilter,
                items: filterOptions.map((option){
                  return DropdownMenuItem(value:option,child: Text(option),);
                }).toList(),
                onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                },
              ),
          ],),
        ),
        backgroundColor: Colors.amberAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          
        Builder(
          builder: (context) {
            final filteredTaskKeys = tasks.keys.where((key) {
                        if (selectedFilter == 'All Tasks') return true;
                        if (selectedFilter == 'Completed') return tasks[key] == true;
                        if (selectedFilter == 'Pending') return tasks[key] == false;
                        return true;
                      }).toList();
        
            return Expanded(
              child: ListView.builder(
                itemCount: filteredTaskKeys.length,
                itemBuilder: (context, index) {
                  

                  final taskName = filteredTaskKeys[index];
                  return Slidable(
                    endActionPane: ActionPane(motion: StretchMotion(), children: [
                      SlidableAction(
                        onPressed: (context) {
                          final taskName = filteredTaskKeys[index];
                          final deletedTaskName = taskName;
                          final deletedTaskStatus = tasks[taskName];
                          setState(() {
                            tasks.remove(taskName);
                            myTasks.delete(taskName);
                          });
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task deleted'),
                            action: SnackBarAction(label: 'Undo', onPressed: () {
                              setState(() {
                                tasks[deletedTaskName] = deletedTaskStatus!; 
                              });
                            }),
                            )
                           );
                        },
                        icon: Icons.delete,
                        backgroundColor: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      )
                    ]),
                    child: GestureDetector(
                      onLongPress: (){
                        edittaskcontroller.text = taskName;
                        showDialog(context: context, builder: (context) {
                          return AlertDialog(
                            title: Text('Edit task'),
                            content: TextField(
                              controller: edittaskcontroller,
                              autocorrect: true,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Enter New Task',
                              ),
                            ),
                            actions: [
                              OutlinedButton(onPressed: () {
                               final newTask = edittaskcontroller.text.trim();

                               if (newTask.isNotEmpty && !tasks.containsKey(newTask)){
                                final value = tasks[taskName];
                                setState(() {
                                  tasks.remove(taskName);
                                  tasks[newTask] = value;
                                  myTasks.delete(taskName);
                                  myTasks.put(newTask, value);
                                  
                                });
                                Navigator.pop(context);
                               }
                              }, child: Text('Save')),
                              OutlinedButton(onPressed: (){
                                Navigator.pop(context);
                              }, child:Text('Cancel',
                              ),)
                            ],
                          );
                        });
                      },
                      child: CheckboxListTile(
                        value: tasks[taskName],
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.amber[200],
                        onChanged: (bool? status) {
                          setState(() {
                            tasks[taskName] = status!;
                            myTasks.put(taskName, status);
                          });
                        },
                        title: Text(
                          taskName,
                          style: TextStyle(
                            fontSize: 18,
                            decoration: tasks[taskName]! ? TextDecoration.lineThrough : null,
                          )
                            ),),
                    ),
                  ); },
              ),
            );
          },
        ),
       if(_showtextfield)
         Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
                      autofocus: true,
                      autocorrect: true,
                      controller: taskcontroller,
                      decoration: InputDecoration(
                        hintText:'Add Task',
                        border: OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children:[IconButton(onPressed: (){
                            setState(() {
                              if (taskcontroller.text.trim().isNotEmpty) {
                             String newTask = taskcontroller.text.trim();
                             tasks[newTask] = false;
                             myTasks.put(newTask, false);
                              taskcontroller.clear();
                              _showtextfield = false;
                        }
                            });
                          }, icon: Icon(Icons.check)),
          
                            IconButton(onPressed: 
                          () {
                            taskcontroller.clear();
                          }, icon: Icon(Icons.clear)),
                          ]
                        )
                      ),
                    ),
        ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: Size.fromHeight(25),
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
              ),
              onPressed:() {
                setState(() {
                  _showtextfield = true;
                });
            },
            child: Icon(Icons.add, color: Colors.grey[600],size: 20,),),
          )
  ])
  );}
}