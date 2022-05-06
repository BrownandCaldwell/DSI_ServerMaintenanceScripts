import json

def write(name, trigger, action):
    print("Made task for '{0}'".format(name))
    template = open('ApplicationTask.xml', encoding='utf-16').read()
    task = template\
        .replace('<URI></URI>','<URI>{0}</URI>'.format(name))\
        .replace('<Triggers></Triggers>','<Triggers>{0}</Triggers>'.format(trigger))\
        .replace('<args>','{0}'.format(action))
    with open(name.replace("\\","_")+".xml", 'w', encoding='utf-16') as outF: outF.write(task)
    
triggers = {
    'Weekly': '''    <CalendarTrigger>
      <StartBoundary>2021-01-01T13:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByWeek>
        <DaysOfWeek>
          <Wednesday />
        </DaysOfWeek>
        <WeeksInterval>1</WeeksInterval>
      </ScheduleByWeek>
    </CalendarTrigger>
    ''',
    'Weekly2': '''    <CalendarTrigger>
      <StartBoundary>2021-01-01T17:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByWeek>
        <DaysOfWeek>
          <Wednesday />
        </DaysOfWeek>
        <WeeksInterval>1</WeeksInterval>
      </ScheduleByWeek>
    </CalendarTrigger>
    ''',
    'Daily' : '''    <CalendarTrigger>
      <StartBoundary>2021-01-01T01:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
    ''',
    'Hourly': '''    <CalendarTrigger>
      <Repetition>
        <Interval>PT1H</Interval>
        <Duration>P1D</Duration>
        <StopAtDurationEnd>true</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2021-01-01T00:00:00</StartBoundary>
      <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
    '''
    }

rules = json.load(open('VM_Governance.json', encoding='utf-8'))
# print(rules)

for rule in rules['Applications']:
    process = rule['Check'].split(' ')[0]
    trigger = triggers[rule['Frequency']]
    message = rule['Message']
    if "messageAddendum" in rules:
        message += "<br><br>" + rules["messageAddendum"]
    action = '.\CleanProcess.ps1 {0} {1} "{2}" "{3}"'.format(process,rule['UserState'],rule['Action'],message)
    write(rule['Check'], trigger, action)

for rule in rules['Directories']:
    directory = rule['Path']
    trigger = triggers[rule['Frequency']]
    action = '.\CleanDirectory.ps1 "{0}" {1} {2} {3}'.format(directory,rule['Age'],rule['Size Limit GB'],rule['Action'])
    if 'Message' in rule: 
        message = rule['Message']
        if "messageAddendum" in rules:
            message += "\n\n" + rules["messageAddendum"]
        action += ' "\'{0}\'"'.format(message)
    write(rule['Check'], trigger, action)
    
