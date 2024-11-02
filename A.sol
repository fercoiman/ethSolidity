//natspec
// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract TaskManager {

    enum TaskStatus {
        Pending,
        InProgress,
        Done
    }

    struct Task {
        uint256 id;
        string title;
        TaskStatus status;
    }

    event TaskCreated(uint256 indexed id, string title);

    Task[] public tasks;
    uint256 public taskCounter;
    uint256 constant MAX_TASK= 10;

    //createTask
    function createTask(string calldata _title) external {
        require(bytes(_title).length > 0,"empty title");
        if(taskCounter >= MAX_TASK) {
            revert("maximum achieved");
        }
        tasks.push( Task(taskCounter, _title, TaskStatus.Pending) );
        emit TaskCreated(taskCounter, _title);
        taskCounter++;
    }

    modifier validTaskIndex(uint256 _id) {
        require(_id < tasks.length, "id does not exist");
        _;
    }
    
    //updateTaskStatus
    function updateTaskStatus(uint256 _id, TaskStatus _status) external validTaskIndex(_id) {
        tasks[_id].status = _status;
    }

    // readNextToDo
    function readNextToDo() external view returns(Task memory) {
        uint256 taskLen = tasks.length;
        for(uint256 i=0 ; i < taskLen ; i++) {
            if(tasks[i].status == TaskStatus.Pending) {
                return tasks[i];
            }
        }
        return tasks[taskLen-1];
    }

    //deleteLastTask // pop

}