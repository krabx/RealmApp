//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    private let storageManager = StorageManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.title
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.title
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        
        let deleteButton = UIContextualAction(style: .destructive, title: nil) { [unowned self] _, _, _ in
            storageManager.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editButton = UIContextualAction(style: .normal, title: nil) { [unowned self] _, _, isDone in
            showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneButton = UIContextualAction(style: .normal, title: nil) { [unowned self] _, _, isDone in
            storageManager.complete(task) { task in
                let completedIndex = IndexPath(row: completedTasks.index(of: task) ?? 0, section: 1)
                tableView.moveRow(at: indexPath, to: completedIndex)
            }
            isDone(true)
        }
        
        let unDoneButton = UIContextualAction(style: .normal, title: nil) { [unowned self] _, _, isDone in
            storageManager.complete(task) { task in
                let currentIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
                tableView.moveRow(at: indexPath, to: currentIndex)
            }
            isDone(true)
        }
        
        deleteButton.image = UIImage(systemName: "bin.xmark")
        
        editButton.image = UIImage(systemName: "wrench")
        
        doneButton.image = UIImage(systemName: "checkmark")
        doneButton.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        
        unDoneButton.image = UIImage(systemName: "arrow.uturn.backward")
        unDoneButton.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
        
        return task.isComplete != true
        ? UISwipeActionsConfiguration(actions: [doneButton, editButton, deleteButton])
        : UISwipeActionsConfiguration(actions: [unDoneButton, editButton, deleteButton])

    }
}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let taskAlertFactory = TaskAlertControllerFactory(
            userAction: task != nil ? .editTask : .newTask,
            taskTitle: task?.title,
            taskNote: task?.note
        )
        let alert = taskAlertFactory.createAlert { [weak self] taskTitle, taskNote in
            if let task, let completion {
                self?.storageManager.edit(task, newTaskName: taskTitle, newTaskNote: taskNote)
                completion()
                return
            } else {
                self?.save(task: taskTitle, withNote: taskNote)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(task: String, withNote note: String) {
        storageManager.save(task, withTaskNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}
