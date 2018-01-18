import React,{Component}   from 'react'
import moment              from 'moment'
import { Icon, Table,Menu, Button, Header, Image, Modal, List, Label} from 'semantic-ui-react'
import prettyMs            from 'pretty-ms'
class  DataTable extends Component

  render:->
    me = @ 
    times  =  _.get me, 'props.data.createdAt'
    time = moment(times).utcOffset("+07:00")
    unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD") > 0
      dateTime = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
    else
      dateTime = moment(times).utcOffset('+07:00').format("DD-MM-YYYY")
    <Table.Row  style={{"height": "100%"}}>
    <Table.Cell>{_.get me, 'props.data.id'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.username'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.servername'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.command'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.request_method'}</Table.Cell>
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
                <Label color='red' horizontal><Icon name='user' /> servername</Label>
                 {_.get me, 'props.data.username'}
              </List.Item>
              <List.Item>
                <Label color='purple' horizontal><Icon name='server' />username</Label>
                 {_.get me, 'props.data.servername'}
              </List.Item>
              <List.Item>
                <Label color='red' horizontal><Icon name='barcode' />command</Label>
                {_.get me, 'props.data.command'}
              </List.Item>
              <List.Item>
                <Label color='purple' horizontal><Icon name='time' />time</Label>
                {_.get me, 'props.data.request_method'}
              </List.Item>
              <List.Item>
                <Label color='purple' horizontal><Icon name='time' />time</Label>
                {_.get me, 'props.data.createdAt'}
              </List.Item>
              <List.Item>
                <Label color='purple' horizontal><Icon name='checkmark box' />allow</Label>
                {(_.get me, 'props.data.allow').toString()}
              </List.Item>
            </List>
              
            </Modal.Description>
          </Modal.Content>
        </Modal>
      </Table.Cell>
    </Table.Row>
    
export default DataTable

