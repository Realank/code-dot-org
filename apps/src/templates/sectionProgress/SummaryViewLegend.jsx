import React, { PropTypes, Component } from 'react';
import ProgressBox from './ProgressBox';

const styles = {
  progressBox: {
    float: 'left',
    padding: 10,
    width: '20%',
  }
};

export default class SummaryViewLegend extends Component {
  static propTypes = {
    showCSFProgressBox: PropTypes.bool
  };

  render() {

    return (
      <div style={{width:400, border: '1px solid light_gray'}}>
        <div style={styles.progressBox}>
          <div>Not started</div>
          <ProgressBox
            started={false}
            incomplete={20}
            imperfect={0}
            perfect={0}
          />
        </div>
        <div style={styles.progressBox}>
          <div>Started</div>
          <ProgressBox
            started={true}
            incomplete={20}
            imperfect={0}
            perfect={0}
          />
        </div>
        <div style={styles.progressBox}>
          <div>Completed</div>
          <ProgressBox
            started={true}
            incomplete={0}
            imperfect={0}
            perfect={20}
          />
        </div>
        <div style={styles.progressBox}>
          <div>Completed</div>
          <ProgressBox
            started={true}
            incomplete={0}
            imperfect={20}
            perfect={0}
          />
        </div>
      </div>
    );
  }
}
