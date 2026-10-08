# LAMP Project

## Overview
The LAMP project is an open-source infrastructure and application design effort aimed at creating a consistent development and deployment environment using a modern, repeatable architecture. The project combines Linux, Apache, PHP, MariaDB, virtual machines, Vagrant, and Salt to build a reliable environment for local development and production-like testing.

The goal is to design a stack that is easy to reproduce, easy to automate, and consistent across environments, reducing the risk of configuration drift between developers and deployment targets.

## Project Objective
This project explores how to use open-source tooling to create a stable and scalable environment for web application development. It focuses on:

- Building a Debian-based virtual machine in VMware
- Installing and validating the LAMP stack
- Developing a PHP and MariaDB listing application
- Automating both development and production-like environments

## Technology Stack
- Debian Linux
- VMware virtualization
- Apache HTTP Server
- PHP
- MariaDB
- Vagrant
- Salt

## Project Tasks

### Task 1: Create a Debian VM in VMware
Set up a clean Debian virtual machine in VMware as the foundation for the environment. This VM acts as the base operating system for the web stack and serves as a consistent platform for development and testing.

### Task 2: Install and Verify the LAMP Stack
Install and configure the core components of the stack:

- Apache web server
- PHP runtime
- MariaDB database server

Verify that the services are correctly installed and working together before building the application.

### Task 3: Build the PHP/MariaDB Listing Application
Develop a simple web application that connects to MariaDB and displays records from a database. This application will demonstrate the functionality of the complete LAMP environment and serve as a practical example of how the stack works in real use.

### Task 4: Automate Dev and Production-Like Environments
Use Vagrant and Salt to automate the configuration of environments. This ensures that the same setup can be reproduced consistently across development and near-production environments, reducing manual setup errors and improving maintainability.

## Why This Project Matters
The main value of this project is consistency. By using virtual machines and automation tools, the environment becomes easier to recreate, test, and deploy. This approach reduces friction for developers and creates a more reliable software delivery process.

## Summary
The LAMP project is a practical attempt to build a repeatable, open-source web stack using Debian virtual machines, Apache, PHP, MariaDB, Vagrant, and Salt. It demonstrates how a development environment can be standardized and automated while also supporting a production-like deployment workflow.

This project is intended to serve as both a learning exercise and a foundation for building reliable, portable web application environments.

## Working session rules

This project is intentionally treated as a learning exercise, not as a single large unattended installation script. Each task is completed in its own working session or conversation, and the final state of that task must be written down before moving to the next one.

### Required documentation before advancing
Before starting Task 2, Task 3, or Task 4, the current task must be documented in this README with:

- the task goal
- the final commands used
- important decisions and configuration choices
- any errors encountered
- the actual fix applied
- verification results
- the final working state
- what was learned

This creates a living project record that explains the environment far more clearly than a single unexplained automation script.

### Task notes and learning log
Each successful task should end with a short notes section describing:

- what was implemented
- what was learned
- which commands actually worked
- which mistakes or failures were corrected
- what should be reviewed or rewritten in a future pass

These notes are meant to preserve the practical knowledge from each session and make the project easier to understand later.

### Draft status
The task files in this repository are working drafts. They will be reviewed and rewritten when the actual work begins for each task, and the final versions should reflect the real environment and decisions made during implementation.

Current task draft files:

- [Task1-Debian-VM.md](Task1-Debian-VM.md)
- [Task2-LAMP-stack.md](Task2-LAMP-stack.md)
- [Task3-Listing-application.md](Task3-Listing-application.md)
- [Task4-Automation-and-environments.md](Task4-Automation-and-environments.md)

## Task completion template

Use this template for each successful task before advancing:

### Task X: <name>
- Goal:
- Environment:
- Final commands:
- Decisions made:
- Errors encountered:
- Fixes applied:
- Verification results:
- Success criteria met:
- Lessons learned:
- What to improve next time:

This section will eventually form the project history and make the setup understandable without relying on hidden assumptions or memory.
