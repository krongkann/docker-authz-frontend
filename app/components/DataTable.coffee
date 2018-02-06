import React,{Component}   from 'react'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import { Icon, 
  Table, 
  Button, 
  Header, 
  Modal, 
  List, 
  Label}                  from 'semantic-ui-react'

class  DataTable extends Component

  render:->
    me = @ 
    times  =  _.get me, 'props.data.createdAt'
    time = moment(times).utcOffset("+07:00")
    activity = _.get me, 'props.data.activity'
    if activity is 'true' or activity is 'false' or activity is 'null'
      activity = "--"
    unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD") > 0
      dateTime = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
    else
      dateTime = moment(times).utcOffset('+07:00').format("DD-MM-YYYY")
    <Table.Row  style={{"height": "100%"}}>
    <Table.Cell>{_.get me, 'props.data.id'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.username'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.servername'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.command'} </Table.Cell>
      <Table.Cell>{dateTime} </Table.Cell>
      <Table.Cell> 
        <Modal size='tiny' style={height: '50%'}  trigger={<Button color='pink' size='tiny' animated='vertical'>
          <Button.Content hidden>Detail</Button.Content>
          <Button.Content visible>
            <Icon name='question circle outline' />
          </Button.Content>
          </Button>}>
          <Modal.Header>Datail</Modal.Header>
          <Modal.Content size='tiny' >
            <Modal.Description>
            <List divided selection>
              <List.Item>
                <Label color='red' horizontal><Icon name='user' /> Servername</Label>
                 {_.get me, 'props.data.username'}
              </List.Item>
              <List.Item>
                <Label color='orange' horizontal><Icon name='server' />Username</Label>
                 {_.get me, 'props.data.servername'}
              </List.Item>
              <List.Item>
                <Label color='yellow' horizontal><Icon name='barcode' />Command</Label>
                {_.get me, 'props.data.command'}
              </List.Item>
              <List.Item>
                <Label color='green' horizontal><Icon name='time' />time</Label>
                {dateTime}
              </List.Item>
              <List.Item>
                <Label color='teal' horizontal><Icon name='checkmark box' />Allow</Label>
                {(_.get me, 'props.data.allow').toString()}
              </List.Item>
              <List.Item>
                <Label color='blue' horizontal><Icon name='user circle' />Admin</Label>
                {activity}
              </List.Item>
            </List>
              
            </Modal.Description>
          </Modal.Content>
        </Modal>
      </Table.Cell>
    </Table.Row>
    
export default DataTable

