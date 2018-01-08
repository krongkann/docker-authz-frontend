import React,{Component}   from 'react'
import moment              from 'moment'
import { Dropdown, Label, Select, Grid, Button, Menu, Input } from 'semantic-ui-react'

class  MenuOption extends Component

  render:->
    me = @ 
    <Menu size='large' vertical>
      <Menu.Item name='inbox' >
        <Label color='teal'>1</Label>
        Inbox
      </Menu.Item>
      <Menu.Item name='spam' >
        <Label>51</Label>
        Spam
      </Menu.Item>

      <Menu.Item name='updates'  >
        <Label>1</Label>
        Updates
      </Menu.Item>
      <Menu.Item>
        <Input icon='search'  />
      </Menu.Item>
    </Menu>
    
export default MenuOption

