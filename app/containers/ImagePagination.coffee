import React,{Component}                from 'react'
import { connect }                      from 'react-redux'
import ImageTable                       from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import { Icon, Table,Menu, Label }      from 'semantic-ui-react'
class  ImagePagination extends Component
  
  render: ->
    me = @
    disablednext =  ((_.get @, 'props.cursorend.endCursor') == me.props.cursor) or !me.props.totals
    disabledback = (me.props.page == 1)
    <Table.Footer>
      <Table.Row>
        <Table.HeaderCell colSpan='12 '>
          <Menu floated='right'   pagination>
            <Menu.Item as='a' 
              disabled={disabledback}
              onClick={(cursor)->
                    me.props.onClick(-1)
                    me.props.onPageBack(cursor)} icon>
              <Icon name='left chevron' />
              {" "}
                Back
            </Menu.Item>
            <Menu.Item as='a'
              disabled = {disablednext}
              onClick={(cursor,s)-> 
                      me.props.onClick(1)
                      me.props.onPageNext(cursor)} icon>
              Next
              <Icon name='right chevron' />
            </Menu.Item>
          </Menu>
          <Label>
            PAGE :
            <Label.Detail>{me.props.page}</Label.Detail>
          </Label>
        </Table.HeaderCell>
      </Table.Row>
    </Table.Footer>

mapStateToProps = ({image})=>
  cursorend: image.endcursor
  page: image.numberpage
mapDispatchToProps = (dispatch) =>
  onClick:(me)->
    dispatch imageActions.pageNumber(me)

export default connect(mapStateToProps,mapDispatchToProps)(ImagePagination)
